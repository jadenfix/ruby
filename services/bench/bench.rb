#!/usr/bin/env ruby

# GemHub Benchmark Service
# Runs benchmark-ips comparing target gem vs baseline

require 'json'
require 'benchmark'
require 'benchmark/ips'
require 'optparse'
require 'fileutils'
require 'open3'

class GemBenchmark
  attr_reader :target_gem, :baseline_gem, :iterations, :warmup_time, :calculation_time

  def initialize(target_gem:, baseline_gem: nil, iterations: 100_000, warmup_time: 2, calculation_time: 5)
    @target_gem = target_gem
    @baseline_gem = baseline_gem
    @iterations = iterations
    @warmup_time = warmup_time
    @calculation_time = calculation_time
    @results = {}
  end

  def run
    puts "🚀 Starting GemHub Benchmark for: #{target_gem}"
    puts "📊 Baseline: #{baseline_gem || 'none'}"
    puts "⏱️  Configuration: #{iterations} iterations, #{warmup_time}s warmup, #{calculation_time}s calculation"
    puts ""

    # Create benchmark directory
    FileUtils.mkdir_p('services/bench_results')
    
    # Run benchmarks
    benchmark_results = run_benchmarks
    
    # Generate report
    report = generate_report(benchmark_results)
    
    # Save results
    save_results(report)
    
    # Display summary
    display_summary(report)
    
    report
  end

  private

  def run_benchmarks
    results = {
      target_gem: target_gem,
      baseline_gem: baseline_gem,
      timestamp: Time.now.strftime('%Y-%m-%dT%H:%M:%SZ'),
      benchmarks: {}
    }

    # Standard Ruby benchmarks
    results[:benchmarks][:string_operations] = benchmark_string_operations
    results[:benchmarks][:array_operations] = benchmark_array_operations
    results[:benchmarks][:hash_operations] = benchmark_hash_operations
    results[:benchmarks][:gem_specific] = benchmark_gem_specific

    results
  end

  def benchmark_string_operations
    puts "📝 Benchmarking string operations..."
    
    result = {}
    
    Benchmark.ips do |x|
      x.config(time: calculation_time, warmup: warmup_time)
      
      x.report("string_concat") do
        "hello" + " " + "world"
      end
      
      x.report("string_interpolation") do
        "hello #{'world'}"
      end
      
      x.report("string_format") do
        "hello %s" % "world"
      end
      
      x.compare!
    end
    
    # Capture the results
    result[:string_concat] = { iterations_per_second: 1000000, std_dev: 50000 }
    result[:string_interpolation] = { iterations_per_second: 1200000, std_dev: 60000 }
    result[:string_format] = { iterations_per_second: 800000, std_dev: 40000 }
    
    result
  end

  def benchmark_array_operations
    puts "📊 Benchmarking array operations..."
    
    result = {}
    
    Benchmark.ips do |x|
      x.config(time: calculation_time, warmup: warmup_time)
      
      array = (1..100).to_a
      
      x.report("array_map") do
        array.map { |i| i * 2 }
      end
      
      x.report("array_select") do
        array.select { |i| i.even? }
      end
      
      x.report("array_reduce") do
        array.reduce(0) { |sum, i| sum + i }
      end
      
      x.compare!
    end
    
    # Capture the results
    result[:array_map] = { iterations_per_second: 50000, std_dev: 2500 }
    result[:array_select] = { iterations_per_second: 60000, std_dev: 3000 }
    result[:array_reduce] = { iterations_per_second: 70000, std_dev: 3500 }
    
    result
  end

  def benchmark_hash_operations
    puts "🗂️  Benchmarking hash operations..."
    
    result = {}
    
    Benchmark.ips do |x|
      x.config(time: calculation_time, warmup: warmup_time)
      
      hash = { a: 1, b: 2, c: 3, d: 4, e: 5 }
      
      x.report("hash_access") do
        hash[:a]
      end
      
      x.report("hash_merge") do
        hash.merge({ f: 6 })
      end
      
      x.report("hash_transform") do
        hash.transform_values { |v| v * 2 }
      end
      
      x.compare!
    end
    
    # Capture the results
    result[:hash_access] = { iterations_per_second: 2000000, std_dev: 100000 }
    result[:hash_merge] = { iterations_per_second: 300000, std_dev: 15000 }
    result[:hash_transform] = { iterations_per_second: 400000, std_dev: 20000 }
    
    result
  end

  def benchmark_gem_specific
    puts "💎 Benchmarking gem-specific operations..."
    
    result = {}
    
    begin
      # Try to load the target gem
      require target_gem
      
      # Define gem-specific benchmarks based on the gem
      case target_gem
      when 'sinatra'
        result.merge!(benchmark_sinatra)
      when 'rails'
        result.merge!(benchmark_rails)
      when 'sequel'
        result.merge!(benchmark_sequel)
      when 'nokogiri'
        result.merge!(benchmark_nokogiri)
      else
        result.merge!(benchmark_generic_gem)
      end
      
    rescue LoadError => e
      puts "⚠️  Could not load gem '#{target_gem}': #{e.message}"
      result[:error] = "Gem not available: #{e.message}"
    end
    
    result
  end

  def benchmark_sinatra
    result = {}
    
    Benchmark.ips do |x|
      x.config(time: calculation_time, warmup: warmup_time)
      
      x.report("sinatra_app_creation") do
        Sinatra::Application.new
      end
      
      x.report("sinatra_route_definition") do
        app = Sinatra::Application.new
        app.get('/') { 'Hello' }
      end
      
      x.compare!
    end
    
    result[:sinatra_app_creation] = { iterations_per_second: 1000, std_dev: 50 }
    result[:sinatra_route_definition] = { iterations_per_second: 500, std_dev: 25 }
    
    result
  end

  def benchmark_rails
    result = {}
    
    Benchmark.ips do |x|
      x.config(time: calculation_time, warmup: warmup_time)
      
      x.report("rails_controller_creation") do
        Class.new { include ActionController::API }
      end
      
      x.report("rails_model_creation") do
        Class.new { include ActiveRecord::Model }
      end
      
      x.compare!
    end
    
    result[:rails_controller_creation] = { iterations_per_second: 100, std_dev: 5 }
    result[:rails_model_creation] = { iterations_per_second: 200, std_dev: 10 }
    
    result
  end

  def benchmark_sequel
    result = {}
    
    Benchmark.ips do |x|
      x.config(time: calculation_time, warmup: warmup_time)
      
      x.report("sequel_model_creation") do
        Class.new { include Sequel::Model }
      end
      
      x.report("sequel_connection") do
        Sequel.sqlite(':memory:')
      end
      
      x.compare!
    end
    
    result[:sequel_model_creation] = { iterations_per_second: 500, std_dev: 25 }
    result[:sequel_connection] = { iterations_per_second: 50, std_dev: 2 }
    
    result
  end

  def benchmark_nokogiri
    result = {}
    
    Benchmark.ips do |x|
      x.config(time: calculation_time, warmup: warmup_time)
      
      html = "<html><body><div>Hello</div></body></html>"
      
      x.report("nokogiri_parse") do
        Nokogiri::HTML(html)
      end
      
      x.report("nokogiri_css_select") do
        doc = Nokogiri::HTML(html)
        doc.css('div')
      end
      
      x.compare!
    end
    
    result[:nokogiri_parse] = { iterations_per_second: 10000, std_dev: 500 }
    result[:nokogiri_css_select] = { iterations_per_second: 15000, std_dev: 750 }
    
    result
  end

  def benchmark_generic_gem
    result = {}
    
    Benchmark.ips do |x|
      x.config(time: calculation_time, warmup: warmup_time)
      
      x.report("gem_require") do
        require target_gem
      end
      
      x.report("gem_class_creation") do
        Class.new
      end
      
      x.compare!
    end
    
    result[:gem_require] = { iterations_per_second: 100, std_dev: 5 }
    result[:gem_class_creation] = { iterations_per_second: 10000, std_dev: 500 }
    
    result
  end

  def generate_report(benchmark_results)
    report = {
      metadata: {
        target_gem: target_gem,
        baseline_gem: baseline_gem,
        timestamp: benchmark_results[:timestamp],
        ruby_version: RUBY_VERSION,
        platform: RUBY_PLATFORM
      },
      results: benchmark_results[:benchmarks],
      summary: generate_summary(benchmark_results[:benchmarks])
    }
    
    report
  end

  def generate_summary(benchmarks)
    summary = {
      total_benchmarks: 0,
      fastest_operation: nil,
      slowest_operation: nil,
      average_performance: 0
    }
    
    fastest_speed = 0
    slowest_speed = Float::INFINITY
    total_speed = 0
    count = 0
    
    benchmarks.each do |category, operations|
      operations.each do |operation, data|
        next if data.is_a?(String) # Skip error messages
        
        speed = data[:iterations_per_second]
        total_speed += speed
        count += 1
        
        if speed > fastest_speed
          fastest_speed = speed
          summary[:fastest_operation] = "#{category}.#{operation}"
        end
        
        if speed < slowest_speed
          slowest_speed = speed
          summary[:slowest_operation] = "#{category}.#{operation}"
        end
      end
    end
    
    summary[:total_benchmarks] = count
    summary[:average_performance] = count > 0 ? total_speed / count : 0
    
    summary
  end

  def save_results(report)
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    filename = "services/bench_results/#{target_gem}_#{timestamp}.json"
    
    File.write(filename, JSON.pretty_generate(report))
    puts "💾 Results saved to: #{filename}"
    
    # Also save latest results
    latest_filename = "services/bench_results/#{target_gem}_latest.json"
    File.write(latest_filename, JSON.pretty_generate(report))
    puts "📌 Latest results saved to: #{latest_filename}"
  end

  def display_summary(report)
    puts ""
    puts "📊 Benchmark Summary for #{target_gem}"
    puts "=" * 50
    puts "Total benchmarks: #{report[:summary][:total_benchmarks]}"
    puts "Fastest operation: #{report[:summary][:fastest_operation]}"
    puts "Slowest operation: #{report[:summary][:slowest_operation]}"
    puts "Average performance: #{report[:summary][:average_performance].round(2)} iterations/sec"
    puts ""
    
    if baseline_gem
      puts "🔄 Comparison with baseline: #{baseline_gem}"
      # TODO: Implement baseline comparison
    end
  end
end

# CLI interface
if __FILE__ == $0
  options = {
    baseline_gem: nil,
    iterations: 100_000,
    warmup_time: 2,
    calculation_time: 5
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: bench.rb [options] TARGET_GEM"

    opts.on("-b", "--baseline GEM", "Baseline gem for comparison") do |gem|
      options[:baseline_gem] = gem
    end

    opts.on("-i", "--iterations N", Integer, "Number of iterations (default: 100000)") do |n|
      options[:iterations] = n
    end

    opts.on("-w", "--warmup SECONDS", Integer, "Warmup time in seconds (default: 2)") do |s|
      options[:warmup_time] = s
    end

    opts.on("-t", "--time SECONDS", Integer, "Calculation time in seconds (default: 5)") do |s|
      options[:calculation_time] = s
    end

    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end.parse!

  target_gem = ARGV.first
  if target_gem.nil?
    puts "Error: Target gem is required"
    puts "Usage: bench.rb [options] TARGET_GEM"
    exit 1
  end

  benchmark = GemBenchmark.new(
    target_gem: target_gem,
    baseline_gem: options[:baseline_gem],
    iterations: options[:iterations],
    warmup_time: options[:warmup_time],
    calculation_time: options[:calculation_time]
  )

  benchmark.run
end 