#!/usr/bin/env ruby
# frozen_string_literal: true

# End-to-End Tests for GemHub Platform
# Tests the full stack: API, CLI, and integration scenarios

require 'minitest/autorun'
require 'minitest/reporters'
require 'net/http'
require 'json'
require 'uri'
require 'fileutils'
require 'open3'
require 'timeout'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class GemHubE2ETest < Minitest::Test
  API_BASE_URL = 'http://localhost:4567'
  CLI_PATH = File.expand_path('../cli/bin/gemhub', __dir__)
  API_TOKEN = 'test-token'
  
  def setup
    @test_dir = "/tmp/gemhub_e2e_test_#{Time.now.to_i}"
    FileUtils.mkdir_p(@test_dir)
    
    # Set environment variables for tests
    ENV['GEMHUB_API_URL'] = API_BASE_URL
    ENV['GEMHUB_API_TOKEN'] = API_TOKEN
    ENV['PATH'] = "/opt/homebrew/opt/ruby/bin:#{ENV['PATH']}"
    
    # Verify API is running
    assert api_healthy?, "API server must be running on #{API_BASE_URL}"
  end
  
  def teardown
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
  end
  
  # === API Tests ===
  
  def test_api_health_check
    response = make_api_request('GET', '/health')
    assert_equal 200, response.code.to_i
    
    data = JSON.parse(response.body)
    assert_equal 'healthy', data['status']
    assert data['timestamp']
  end
  
  def test_api_authentication
    # Test without auth token
    response = make_api_request('GET', '/gems', auth: false)
    assert_equal 401, response.code.to_i
    
    # Test with auth token
    response = make_api_request('GET', '/gems', auth: true)
    assert_equal 200, response.code.to_i
  end
  
  def test_api_gems_crud
    # List gems
    response = make_api_request('GET', '/gems', auth: true)
    assert_equal 200, response.code.to_i
    
    gems_data = JSON.parse(response.body)
    assert gems_data['gems'].is_a?(Array)
    initial_count = gems_data['gems'].length
    
    # Create a new gem
    new_gem = {
      name: "test-e2e-gem",
      version: "1.0.0",
      description: "E2E test gem",
      homepage: "https://example.com",
      license: "MIT"
    }
    
    response = make_api_request('POST', '/gems', 
      body: new_gem.to_json, 
      headers: { 'Content-Type' => 'application/json' },
      auth: true
    )
    assert_equal 201, response.code.to_i
    
    created_gem = JSON.parse(response.body)['gem']
    gem_id = created_gem['id']
    assert_equal new_gem[:name], created_gem['name']
    
    # Get the specific gem
    response = make_api_request('GET', "/gems/#{gem_id}", auth: true)
    assert_equal 200, response.code.to_i
    
    # Update the gem
    updated_data = { description: "Updated E2E test gem" }
    response = make_api_request('PUT', "/gems/#{gem_id}",
      body: updated_data.to_json,
      headers: { 'Content-Type' => 'application/json' },
      auth: true
    )
    assert_equal 200, response.code.to_i
    
    updated_gem = JSON.parse(response.body)['gem']
    assert_equal updated_data[:description], updated_gem['description']
    
    # List gems again to verify count increased
    response = make_api_request('GET', '/gems', auth: true)
    gems_data = JSON.parse(response.body)
    assert_equal initial_count + 1, gems_data['gems'].length
    
    # Delete the gem
    response = make_api_request('DELETE', "/gems/#{gem_id}", auth: true)
    assert_equal 200, response.code.to_i
    
    # Verify it's deleted
    response = make_api_request('GET', "/gems/#{gem_id}", auth: true)
    assert_equal 404, response.code.to_i
  end
  
  def test_api_ratings
    # Get existing gems
    response = make_api_request('GET', '/gems', auth: true)
    gems_data = JSON.parse(response.body)
    gem_id = gems_data['gems'].first['id']
    
    # Add a rating
    rating_data = {
      score: 5,
      comment: "Excellent gem for E2E testing!",
      user_id: "e2e-test-user"
    }
    
    response = make_api_request('POST', "/gems/#{gem_id}/ratings",
      body: rating_data.to_json,
      headers: { 'Content-Type' => 'application/json' },
      auth: true
    )
    assert_equal 201, response.code.to_i
    
    # Get ratings for the gem
    response = make_api_request('GET', "/gems/#{gem_id}/ratings", auth: true)
    assert_equal 200, response.code.to_i
    
    ratings = JSON.parse(response.body)['ratings']
    assert ratings.any? { |r| r['comment'] == rating_data[:comment] }
  end
  
  def test_api_badges
    # Get existing gems
    response = make_api_request('GET', '/gems', auth: true)
    gems_data = JSON.parse(response.body)
    gem_id = gems_data['gems'].first['id']
    
    # Create a badge
    badge_data = {
      gem_id: gem_id,
      type: "quality",
      name: "E2E Tested",
      description: "Passes comprehensive E2E tests"
    }
    
    response = make_api_request('POST', '/badges',
      body: badge_data.to_json,
      headers: { 'Content-Type' => 'application/json' },
      auth: true
    )
    assert_equal 201, response.code.to_i
    
    # List all badges
    response = make_api_request('GET', '/badges', auth: true)
    assert_equal 200, response.code.to_i
    
    badges = JSON.parse(response.body)['badges']
    assert badges.any? { |b| b['name'] == badge_data[:name] }
  end
  
  # === CLI Tests ===
  
  def test_cli_list_command
    output, status = run_cli_command(['list'])
    assert_equal 0, status
    assert_includes output, 'GemHub Marketplace'
    assert_includes output, 'sinatra'
    assert_includes output, 'rails'
  end
  
  def test_cli_list_with_limit
    output, status = run_cli_command(['list', '--limit', '2'])
    assert_equal 0, status
    
    # Count gem entries (each gem should have a version in parentheses)
    gem_entries = output.scan(/\([0-9]+\.[0-9]+\.[0-9]+\)/).length
    assert gem_entries <= 2, "Should show at most 2 gems, found #{gem_entries}"
  end
  
  def test_cli_wizard_dry_run
    # Test the wizard command in a controlled way
    # Since wizard is interactive, we'll test the command exists and shows help
    output, status = run_cli_command(['help', 'wizard'])
    assert_equal 0, status
    assert_includes output, 'wizard'
    assert_includes output, 'Interactive gem creator'
  end
  
  def test_cli_publish_help
    output, status = run_cli_command(['help', 'publish'])
    assert_equal 0, status
    assert_includes output, 'publish'
    assert_includes output, 'Publish gem to GemHub marketplace'
  end
  
  # === Integration Tests ===
  
  def test_full_gem_lifecycle
    # Create a test gem via API
    new_gem = {
      name: "integration-test-gem",
      version: "2.0.0", 
      description: "Full integration test gem",
      homepage: "https://integration.example.com",
      license: "Apache-2.0"
    }
    
    response = make_api_request('POST', '/gems',
      body: new_gem.to_json,
      headers: { 'Content-Type' => 'application/json' },
      auth: true
    )
    assert_equal 201, response.code.to_i
    
    created_gem = JSON.parse(response.body)['gem']
    gem_id = created_gem['id']
    
    # Verify it appears in CLI list
    output, status = run_cli_command(['list'])
    assert_equal 0, status
    assert_includes output, 'integration-test-gem'
    assert_includes output, '(2.0.0)'
    
    # Add rating via API
    rating_data = {
      score: 4,
      comment: "Great integration testing!",
      user_id: "integration-user"
    }
    
    response = make_api_request('POST', "/gems/#{gem_id}/ratings",
      body: rating_data.to_json,
      headers: { 'Content-Type' => 'application/json' },
      auth: true
    )
    assert_equal 201, response.code.to_i
    
    # Add badge via API
    badge_data = {
      gem_id: gem_id,
      type: "security",
      name: "Security Tested",
      description: "Passed security integration tests"
    }
    
    response = make_api_request('POST', '/badges',
      body: badge_data.to_json,
      headers: { 'Content-Type' => 'application/json' },
      auth: true
    )
    assert_equal 201, response.code.to_i
    
    # Verify full data via API
    response = make_api_request('GET', "/gems/#{gem_id}", auth: true)
    assert_equal 200, response.code.to_i
    
    gem_data = JSON.parse(response.body)['gem']
    assert_equal 1, gem_data['ratings_count']
    assert_equal 1, gem_data['badges_count']
    assert gem_data['rating'] > 0
    
    # Clean up
    response = make_api_request('DELETE', "/gems/#{gem_id}", auth: true)
    assert_equal 200, response.code.to_i
  end
  
  def test_api_error_handling
    # Test invalid gem creation
    invalid_gem = { name: "invalid!", version: "not-semver" }
    
    response = make_api_request('POST', '/gems',
      body: invalid_gem.to_json,
      headers: { 'Content-Type' => 'application/json' },
      auth: true
    )
    assert_equal 422, response.code.to_i
    
    # Test non-existent gem
    response = make_api_request('GET', '/gems/99999', auth: true)
    assert_equal 404, response.code.to_i
    
    # Test invalid rating
    response = make_api_request('GET', '/gems', auth: true)
    gems_data = JSON.parse(response.body)
    gem_id = gems_data['gems'].first['id']
    
    invalid_rating = { score: 10, user_id: "test" }  # Score too high
    
    response = make_api_request('POST', "/gems/#{gem_id}/ratings",
      body: invalid_rating.to_json,
      headers: { 'Content-Type' => 'application/json' },
      auth: true
    )
    assert_equal 422, response.code.to_i
  end
  
  def test_cli_api_connectivity
    # Test CLI can connect to API
    output, status = run_cli_command(['list'])
    assert_equal 0, status
    refute_includes output, 'connection failed'
    refute_includes output, 'Failed to fetch'
  end
  
  # === Performance Tests ===
  
  def test_api_response_times
    start_time = Time.now
    response = make_api_request('GET', '/health')
    health_time = Time.now - start_time
    
    assert health_time < 1.0, "Health check should respond in < 1 second, took #{health_time}"
    
    start_time = Time.now
    response = make_api_request('GET', '/gems', auth: true)
    gems_time = Time.now - start_time
    
    assert gems_time < 2.0, "Gems list should respond in < 2 seconds, took #{gems_time}"
  end
  
  def test_concurrent_api_requests
    threads = []
    results = []
    
    5.times do
      threads << Thread.new do
        response = make_api_request('GET', '/health')
        results << response.code.to_i
      end
    end
    
    threads.each(&:join)
    
    assert_equal [200] * 5, results, "All concurrent requests should succeed"
  end
  
  private
  
  def api_healthy?
    response = make_api_request('GET', '/health')
    response.code.to_i == 200
  rescue
    false
  end
  
  def make_api_request(method, path, body: nil, headers: {}, auth: false)
    uri = URI("#{API_BASE_URL}#{path}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    
    case method.upcase
    when 'GET'
      request = Net::HTTP::Get.new(uri)
    when 'POST'
      request = Net::HTTP::Post.new(uri)
    when 'PUT'
      request = Net::HTTP::Put.new(uri)
    when 'DELETE'
      request = Net::HTTP::Delete.new(uri)
    end
    
    if auth
      request['Authorization'] = "Bearer #{API_TOKEN}"
    end
    
    headers.each { |key, value| request[key] = value }
    request.body = body if body
    
    http.request(request)
  end
  
  def run_cli_command(args)
    cmd = ['bundle', 'exec', 'ruby', CLI_PATH] + args
    Dir.chdir(File.dirname(CLI_PATH)) do
      Open3.capture2e(*cmd)
    end
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  puts "🧪 Running GemHub End-to-End Tests"
  puts "📡 API URL: #{GemHubE2ETest::API_BASE_URL}"
  puts "🔑 API Token: #{GemHubE2ETest::API_TOKEN}"
  puts "💎 CLI Path: #{GemHubE2ETest::CLI_PATH}"
  puts ""
  
  # Check if API is running
  uri = URI("#{GemHubE2ETest::API_BASE_URL}/health")
  begin
    response = Net::HTTP.get_response(uri)
    if response.code == '200'
      puts "✅ API server is running"
    else
      puts "❌ API server returned #{response.code}"
      exit 1
    end
  rescue => e
    puts "❌ Cannot connect to API server: #{e.message}"
    puts "   Make sure the API server is running on #{GemHubE2ETest::API_BASE_URL}"
    exit 1
  end
  
  puts ""
end 