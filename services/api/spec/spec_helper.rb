require 'rspec'
require 'rack/test'
require 'json'
require 'factory_bot'

# Set environment variables and connect to DB before requiring app
ENV['DATABASE_URL'] = 'sqlite://test.db'
ENV['API_TOKEN'] = 'test-token'
require 'sequel'
DB = Sequel.connect(ENV['DATABASE_URL'])

require_relative '../app'

# Configure RSpec
RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryBot::Syntax::Methods
  
  # Use test database
  ENV['DATABASE_URL'] = 'sqlite://test.db'
  ENV['API_TOKEN'] = 'test-token'
  
  config.before(:each) do
    # Clear database before each test
    DB[:badges].delete
    DB[:ratings].delete
    DB[:gems].delete
  end
  
  config.after(:each) do
    # Clean up after each test
    DB[:badges].delete
    DB[:ratings].delete
    DB[:gems].delete
  end
end

# Define factories
FactoryBot.define do
  to_create { |instance| instance.save }
  factory :gem_record do
    sequence(:name) { |n| "test-gem-#{n}" }
    version { "1.0.0" }
    description { "A test gem" }
    homepage { "https://example.com" }
    license { "MIT" }
    downloads { 1000 }
    rating { 4.0 }
    created_at { Time.now }
    updated_at { Time.now }
  end
  
  factory :rating do
    association :gem_record
    score { 4 }
    comment { "Great gem!" }
    user_id { "test-user" }
    created_at { Time.now }
  end
  
  factory :badge do
    association :gem_record
    type { "quality" }
    name { "Well-Tested" }
    description { "Comprehensive test coverage" }
    created_at { Time.now }
  end
end

# Helper methods
def app
  Sinatra::Application
end

def json_response
  JSON.parse(last_response.body)
end

def auth_headers
  { 'HTTP_AUTHORIZATION' => 'Bearer test-token' }
end 