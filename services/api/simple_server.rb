#!/usr/bin/env ruby
require 'webrick'
require 'json'
require 'cgi'

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
    token = auth_header.gsub('Bearer ', '')
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
        new_gem = {
          id: ($gems.map { |g| g[:id] }.max || 0) + 1,
          name: data['name'],
          version: data['version'],
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
        $gems << new_gem
        
        response.status = 201
        response.body = JSON.generate({ gem: new_gem })
      rescue JSON::ParserError
        response.status = 400
        response.body = JSON.generate({ error: 'Invalid JSON' })
      end
    when '/scan'
      begin
        data = JSON.parse(request.body)
        response.status = 200
        response.body = JSON.generate({
          gem_name: data['gem_name'],
          scan_status: 'completed',
          vulnerabilities: [],
          scan_timestamp: Time.now.iso8601
        })
      rescue JSON::ParserError
        response.status = 400
        response.body = JSON.generate({ error: 'Invalid JSON' })
      end
    else
      response.status = 404
      response.body = JSON.generate({ error: 'Not found' })
    end
  end
end

# Start the server
server = WEBrick::HTTPServer.new(
  Port: 4567,
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
puts "🔑 API Token: #{ENV['API_TOKEN'] || 'test-token'}"
puts ""
puts "Press Ctrl+C to stop the server"

server.start 