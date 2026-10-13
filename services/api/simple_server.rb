#!/usr/bin/env ruby
require 'webrick'
require 'json'
require 'cgi'
require 'time'
require 'fileutils'
require 'thread'

# Simple in-memory data store
$gems = [
  {
    id: 1,
    name: 'sinatra',
    version: '3.0.0',
    description: 'Classy web-development dressed in a DSL',
    homepage: 'http://sinatrarb.com/',
    license: 'MIT',
    downloads: 15000000,
    rating: 4.8,
    ratings_count: 10,
    badges_count: 3,
    created_at: Time.now.iso8601,
    updated_at: Time.now.iso8601
  },
  {
    id: 2,
    name: 'rails',
    version: '7.1.0',
    description: 'Full-stack web application framework',
    homepage: 'https://rubyonrails.org/',
    license: 'MIT',
    downloads: 25000000,
    rating: 4.9,
    ratings_count: 15,
    badges_count: 5,
    created_at: Time.now.iso8601,
    updated_at: Time.now.iso8601
  },
  {
    id: 3,
    name: 'sequel',
    version: '5.68.0',
    description: 'Database toolkit for Ruby',
    homepage: 'https://sequel.jeremyevans.net/',
    license: 'MIT',
    downloads: 8000000,
    rating: 4.7,
    ratings_count: 8,
    badges_count: 2,
    created_at: Time.now.iso8601,
    updated_at: Time.now.iso8601
  },
  {
    id: 4,
    name: 'rspec',
    version: '3.12.0',
    description: 'BDD for Ruby',
    homepage: 'https://rspec.info/',
    license: 'MIT',
    downloads: 12000000,
    rating: 4.6,
    ratings_count: 12,
    badges_count: 4,
    created_at: Time.now.iso8601,
    updated_at: Time.now.iso8601
  },
  {
    id: 5,
    name: 'puma',
    version: '6.3.0',
    description: 'A Ruby web server built for concurrency',
    homepage: 'https://puma.io/',
    license: 'BSD-3-Clause',
    downloads: 18000000,
    rating: 4.5,
    ratings_count: 6,
    badges_count: 3,
    created_at: Time.now.iso8601,
    updated_at: Time.now.iso8601
  }
]

DATA_PATH = File.expand_path(ENV.fetch('GEMHUB_DATA_PATH', 'data/gems.json'), __dir__)
DATA_LOCK = Mutex.new
if File.exist?(DATA_PATH)
  stored = JSON.parse(File.read(DATA_PATH), symbolize_names: true)
  raise 'Gem data must be an array' unless stored.is_a?(Array)
  $gems = stored
end

def persist_gems(records)
  FileUtils.mkdir_p(File.dirname(DATA_PATH))
  temporary = "#{DATA_PATH}.tmp"
  File.open(temporary, 'w', 0600) do |file|
    file.write(JSON.generate(records))
    file.flush
    file.fsync
  end
  File.rename(temporary, DATA_PATH)
end

class APIServer < WEBrick::HTTPServlet::AbstractServlet
  def initialize(server)
    super
    @api_token = ENV['API_TOKEN'] || 'test-token'
  end

  def add_cors_headers(response)
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    response['Content-Type'] = 'application/json'
  end

  def authenticate(request)
    auth_header = request['Authorization']
    return false unless auth_header
    return false unless auth_header.start_with?('Bearer ')
    token = auth_header.delete_prefix('Bearer ')
    token == @api_token
  end

  def do_OPTIONS(request, response)
    add_cors_headers(response)
    response.status = 200
    response.body = ''
  end

  def do_GET(request, response)
    add_cors_headers(response)
    
    path = request.path
    
    case path
    when '/health'
      response.status = 200
      response.body = JSON.generate({
        status: 'healthy',
        timestamp: Time.now.iso8601
      })
    when '/gems'
      unless authenticate(request)
        response.status = 401
        response.body = JSON.generate({ error: 'Unauthorized' })
        return
      end
      
      response.status = 200
      response.body = JSON.generate({ gems: $gems })
    when /^\/gems\/(\d+)$/
      unless authenticate(request)
        response.status = 401
        response.body = JSON.generate({ error: 'Unauthorized' })
        return
      end
      
      gem_id = $1.to_i
      gem = $gems.find { |g| g[:id] == gem_id }
      
      if gem
        response.status = 200
        response.body = JSON.generate({ gem: gem })
      else
        response.status = 404
        response.body = JSON.generate({ error: 'Gem not found' })
      end
    else
      response.status = 404
      response.body = JSON.generate({ error: 'Not found' })
    end
  end

  def do_POST(request, response)
    add_cors_headers(response)
    
    unless authenticate(request)
      response.status = 401
      response.body = JSON.generate({ error: 'Unauthorized' })
      return
    end
    
    path = request.path
    
    case path
    when '/gems'
      begin
        data = JSON.parse(request.body)
        unless data.is_a?(Hash) && data['name'].is_a?(String) && !data['name'].strip.empty? &&
               data['version'].is_a?(String) && !data['version'].strip.empty?
          response.status = 400
          response.body = JSON.generate({ error: 'name and version are required strings' })
          return
        end
        DATA_LOCK.synchronize do
        if $gems.any? { |gem| gem[:name] == data['name'].strip && gem[:version] == data['version'].strip }
          response.status = 409
          response.body = JSON.generate({ error: 'Gem version already exists' })
          return
        end
        new_gem = {
          id: ($gems.map { |g| g[:id] }.max || 0) + 1,
          name: data['name'].strip,
          version: data['version'].strip,
          description: data['description'] || '',
          homepage: data['homepage'] || '',
          license: data['license'] || 'MIT',
          downloads: 0,
          rating: 0.0,
          ratings_count: 0,
          badges_count: 0,
          created_at: Time.now.iso8601,
          updated_at: Time.now.iso8601
        }
        records = $gems + [new_gem]
        persist_gems(records)
        $gems = records
        
        response.status = 201
        response.body = JSON.generate({ gem: new_gem })
        end
      rescue JSON::ParserError
        response.status = 400
        response.body = JSON.generate({ error: 'Invalid JSON' })
      end
    when '/scan'
      response.status = 501
      response.body = JSON.generate({ error: 'Security scanner is not configured; no vulnerability result is available' })
    else
      response.status = 404
      response.body = JSON.generate({ error: 'Not found' })
    end
  end
end

# Start the server
server = WEBrick::HTTPServer.new(
  Port: Integer(ENV.fetch('PORT', '4567')),
  BindAddress: ENV.fetch('BIND_ADDRESS', '127.0.0.1'),
  DocumentRoot: '.',
  Logger: WEBrick::Log.new($stderr, WEBrick::Log::INFO),
  AccessLog: []
)

server.mount('/', APIServer)

# Handle shutdown gracefully
trap('INT') { server.shutdown }
trap('TERM') { server.shutdown }

puts "🚀 GemHub API Server starting on http://localhost:4567"
puts "📚 API Documentation: http://localhost:4567/docs"
puts "💚 Health Check: http://localhost:4567/health"
puts "🔑 Bearer token configured (value omitted)"
puts ""
puts "Press Ctrl+C to stop the server"

server.start 