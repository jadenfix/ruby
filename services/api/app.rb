require 'sinatra'
require 'sinatra/json'
require 'sequel'
require 'json'
require 'rack/contrib'

# Configure Sinatra
set :port, 4567
set :environment, ENV['RACK_ENV'] || 'development'
set :database, ENV['DATABASE_URL'] || 'sqlite://gemhub.db'

# Enable JSON parsing
use Rack::JSONBodyParser

# Enable CORS for frontend
before do
  headers 'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST', 'PUT', 'DELETE'],
          'Access-Control-Allow-Headers' => 'Content-Type, Authorization'
end

# Handle preflight requests
options '*' do
  response.headers['Access-Control-Allow-Origin'] = '*'
  response.headers['Access-Control-Allow-Methods'] = 'HEAD,GET,POST,PUT,DELETE,OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, Authorization'
  200
end

# Database setup
DB = Sequel.connect(ENV['DATABASE_URL'] || settings.database)

# Create tables if they don't exist
unless DB.table_exists?(:gems)
  DB.create_table :gems do
    primary_key :id
    String :name, null: false, unique: true
    String :version, null: false
    String :description
    String :homepage
    String :license
    Integer :downloads, default: 0
    Float :rating, default: 0.0
    DateTime :created_at
    DateTime :updated_at
  end
end

unless DB.table_exists?(:ratings)
  DB.create_table :ratings do
    primary_key :id
    foreign_key :gem_id, :gems, null: false
    Integer :score, null: false
    String :comment
    String :user_id
    DateTime :created_at
  end
end

unless DB.table_exists?(:badges)
  DB.create_table :badges do
    primary_key :id
    foreign_key :gem_id, :gems, null: false
    String :type, null: false
    String :name, null: false
    String :description
    DateTime :created_at
  end
end

# Load models
require_relative 'models/gem'
require_relative 'models/rating'
require_relative 'models/badge'

# Simple token authentication
before do
  unless request.path == '/health' || request.path == '/docs'
    token = request.env['HTTP_AUTHORIZATION']&.gsub('Bearer ', '')
    halt 401, json(error: 'Unauthorized') unless token == ENV['API_TOKEN']
  end
end

# Health check endpoint
get '/health' do
  json(status: 'healthy', timestamp: Time.now.iso8601)
end

# API Documentation
get '/docs' do
  content_type 'text/html'
  <<~HTML
    <!DOCTYPE html>
    <html>
    <head><title>GemHub API Documentation</title></head>
    <body>
      <h1>GemHub API</h1>
      <h2>Endpoints:</h2>
      <ul>
        <li>GET /gems - List all gems</li>
        <li>POST /gems - Create a new gem</li>
        <li>GET /gems/:id - Get a specific gem</li>
        <li>PUT /gems/:id - Update a gem</li>
        <li>DELETE /gems/:id - Delete a gem</li>
        <li>GET /gems/:id/ratings - Get ratings for a gem</li>
        <li>POST /gems/:id/ratings - Add a rating to a gem</li>
        <li>GET /badges - List all badges</li>
        <li>POST /badges - Create a new badge</li>
        <li>POST /scan - Trigger CVE scanner</li>
      </ul>
    </body>
    </html>
  HTML
end

# Gems CRUD
get '/gems' do
  gems = GemRecord.all
  json(gems: gems.map(&:to_hash))
end

post '/gems' do
  data = JSON.parse(request.body.read)
  
  begin
    gem = GemRecord.create(
      name: data['name'],
      version: data['version'],
      description: data['description'],
      homepage: data['homepage'],
      license: data['license'],
      created_at: Time.now,
      updated_at: Time.now
    )
    
    status 201
    json(gem: gem.to_hash)
  rescue Sequel::ValidationFailed => e
    status 422
    json(error: e.message)
  rescue Sequel::UniqueConstraintViolation
    status 409
    json(error: 'Gem already exists')
  end
end

get '/gems/:id' do
  gem = GemRecord[params[:id]]
  halt 404, json(error: 'Gem not found') unless gem
  
  json(gem: gem.to_hash)
end

put '/gems/:id' do
  gem = GemRecord[params[:id]]
  halt 404, json(error: 'Gem not found') unless gem
  
  data = JSON.parse(request.body.read)
  
  begin
    gem.update(
      name: data['name'] || gem.name,
      version: data['version'] || gem.version,
      description: data['description'] || gem.description,
      homepage: data['homepage'] || gem.homepage,
      license: data['license'] || gem.license,
      updated_at: Time.now
    )
    
    json(gem: gem.to_hash)
  rescue Sequel::ValidationFailed => e
    status 422
    json(error: e.message)
  end
end

delete '/gems/:id' do
  gem = GemRecord[params[:id]]
  halt 404, json(error: 'Gem not found') unless gem
  
  gem.destroy
  json(message: 'Gem deleted successfully')
end

# Ratings
get '/gems/:id/ratings' do
  gem = GemRecord[params[:id]]
  halt 404, json(error: 'Gem not found') unless gem
  
  ratings = gem.ratings
  json(ratings: ratings.map(&:to_hash))
end

post '/gems/:id/ratings' do
  gem = GemRecord[params[:id]]
  halt 404, json(error: 'Gem not found') unless gem
  
  data = JSON.parse(request.body.read)
  
  begin
    rating = Rating.create(
      gem_id: gem.id,
      score: data['score'],
      comment: data['comment'],
      user_id: data['user_id'],
      created_at: Time.now
    )
    
    # Update gem's average rating
    avg_rating = Rating.where(gem_id: gem.id).avg(:score) || 0.0
    gem.update(rating: avg_rating)
    
    status 201
    json(rating: rating.to_hash)
  rescue Sequel::ValidationFailed => e
    status 422
    json(error: e.message)
  end
end

# Badges
get '/badges' do
  badges = Badge.all
  json(badges: badges.map(&:to_hash))
end

post '/badges' do
  data = JSON.parse(request.body.read)
  
  begin
    badge = Badge.create(
      gem_id: data['gem_id'],
      type: data['type'],
      name: data['name'],
      description: data['description'],
      created_at: Time.now
    )
    
    status 201
    json(badge: badge.to_hash)
  rescue Sequel::ValidationFailed => e
    status 422
    json(error: e.message)
  end
end

# CVE Scanner endpoint (placeholder for Lane C integration)
post '/scan' do
  data = JSON.parse(request.body.read)
  gem_name = data['gem_name']
  
  # This will be implemented in Lane C
  # For now, return a mock response
  json(
    gem_name: gem_name,
    scan_status: 'pending',
    vulnerabilities: [],
    scan_timestamp: Time.now.iso8601
  )
end

# Error handling
error 404 do
  json(error: 'Not found')
end

error 500 do
  json(error: 'Internal server error')
end 