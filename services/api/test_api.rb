#!/usr/bin/env ruby
require 'sinatra'
require 'json'

set :port, 4568
set :environment, 'development'

get '/health' do
  json(status: 'healthy', timestamp: Time.now.strftime('%Y-%m-%dT%H:%M:%SZ'))
end

get '/test' do
  json(message: 'API is working!')
end

puts "Starting test API on port 4568..."
Sinatra::Application.run!
