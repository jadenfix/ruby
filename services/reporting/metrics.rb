#!/usr/bin/env ruby

# GemHub Reporting Service
# Sends benchmark and CVE results to the API via /metrics endpoint

require 'json'
require 'net/http'
require 'uri'
require 'optparse'
require 'fileutils'
require 'time'

class MetricsReporter
  API_BASE = 'http://localhost:4567'
  
  attr_reader :api_token, :api_base

  def initialize(api_token: ENV['API_TOKEN'], api_base: API_BASE)
    @api_token = api_token
    @api_base = api_base
  end

  def report_benchmark(gem_name, benchmark_file = nil)
    puts "📊 Reporting benchmark results for #{gem_name}..."
    
    # Find benchmark file if not specified
    if benchmark_file.nil?
      latest_file = "services/bench_results/#{gem_name}_latest.json"
      if File.exist?(latest_file)
        benchmark_file = latest_file
      else
        puts "❌ No benchmark results found for #{gem_name}"
        return false
      end
    end
    
    # Load benchmark data
    benchmark_data = load_benchmark_data(benchmark_file)
    
    # Send to API
    success = send_metrics('benchmark', benchmark_data)
    
    if success
      puts "✅ Benchmark results reported successfully"
    else
      puts "❌ Failed to report benchmark results"
    end
    
    success
  end

  def report_cve_scan(gem_name, cve_file = nil)
    puts "🔍 Reporting CVE scan results for #{gem_name}..."
    
    # Find CVE file if not specified
    if cve_file.nil?
      latest_file = "services/cve_scanner/results/#{gem_name}_latest.json"
      if File.exist?(latest_file)
        cve_file = latest_file
      else
        puts "❌ No CVE scan results found for #{gem_name}"
        return false
      end
    end
    
    # Load CVE data
    cve_data = load_cve_data(cve_file)
    
    # Send to API
    success = send_metrics('cve_scan', cve_data)
    
    if success
      puts "✅ CVE scan results reported successfully"
    else
      puts "❌ Failed to report CVE scan results"
    end
    
    success
  end

  def report_sandbox_metrics(gem_name, metrics_data)
    puts "🏖️  Reporting sandbox metrics for #{gem_name}..."
    
    # Prepare sandbox metrics
    sandbox_data = {
      gem_name: gem_name,
      timestamp: Time.now.iso8601,
      metrics: metrics_data
    }
    
    # Send to API
    success = send_metrics('sandbox', sandbox_data)
    
    if success
      puts "✅ Sandbox metrics reported successfully"
    else
      puts "❌ Failed to report sandbox metrics"
    end
    
    success
  end

  def generate_summary_report(gem_name)
    puts "📋 Generating summary report for #{gem_name}..."
    
    # Collect all available data
    report = {
      gem_name: gem_name,
      timestamp: Time.now.iso8601,
      benchmarks: load_benchmark_data("services/bench_results/#{gem_name}_latest.json"),
      cve_scan: load_cve_data("services/cve_scanner/results/#{gem_name}_latest.json"),
      summary: generate_summary(gem_name)
    }
    
    # Save comprehensive report
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    filename = "services/reporting/reports/#{gem_name}_summary_#{timestamp}.json"
    FileUtils.mkdir_p(File.dirname(filename))
    File.write(filename, JSON.pretty_generate(report))
    
    puts "💾 Summary report saved to: #{filename}"
    
    # Send to API
    success = send_metrics('summary', report)
    
    if success
      puts "✅ Summary report sent to API"
    else
      puts "❌ Failed to send summary report to API"
    end
    
    report
  end

  private

  def load_benchmark_data(file_path)
    return nil unless File.exist?(file_path)
    
    begin
      JSON.parse(File.read(file_path))
    rescue JSON::ParserError => e
      puts "⚠️  Error parsing benchmark file: #{e.message}"
      nil
    end
  end

  def load_cve_data(file_path)
    return nil unless File.exist?(file_path)
    
    begin
      JSON.parse(File.read(file_path))
    rescue JSON::ParserError => e
      puts "⚠️  Error parsing CVE file: #{e.message}"
      nil
    end
  end

  def generate_summary(gem_name)
    benchmark_data = load_benchmark_data("services/bench_results/#{gem_name}_latest.json")
    cve_data = load_cve_data("services/cve_scanner/results/#{gem_name}_latest.json")
    
    summary = {
      gem_name: gem_name,
      overall_score: 0,
      performance_score: 0,
      security_score: 0,
      recommendations: []
    }
    
    # Calculate performance score from benchmark data
    if benchmark_data && benchmark_data['summary']
      avg_performance = benchmark_data['summary']['average_performance'] || 0
      summary[:performance_score] = calculate_performance_score(avg_performance)
      summary[:recommendations] << "Performance: #{performance_recommendation(avg_performance)}"
    end
    
    # Calculate security score from CVE data
    if cve_data && cve_data['risk_score']
      summary[:security_score] = 100 - cve_data['risk_score']
      summary[:recommendations] << "Security: #{security_recommendation(cve_data['risk_score'])}"
    end
    
    # Calculate overall score
    summary[:overall_score] = (summary[:performance_score] + summary[:security_score]) / 2
    
    summary
  end

  def calculate_performance_score(avg_performance)
    # Convert iterations per second to a 0-100 score
    case avg_performance
    when 0..1000
      20
    when 1001..10000
      40
    when 10001..100000
      60
    when 100001..1000000
      80
    else
      100
    end
  end

  def performance_recommendation(avg_performance)
    case avg_performance
    when 0..1000
      "Very slow performance - consider optimization"
    when 1001..10000
      "Slow performance - may need improvements"
    when 10001..100000
      "Moderate performance - acceptable for most use cases"
    when 100001..1000000
      "Good performance - suitable for production"
    else
      "Excellent performance - highly optimized"
    end
  end

  def security_recommendation(risk_score)
    case risk_score
    when 0..20
      "Low security risk - safe to use"
    when 21..50
      "Medium security risk - consider updating"
    when 51..80
      "High security risk - update recommended"
    else
      "Critical security risk - update immediately"
    end
  end

  def send_metrics(metric_type, data)
    return false if api_token.nil?
    
    # Prepare the request
    uri = URI("#{api_base}/metrics")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{api_token}"
    
    # Prepare payload
    payload = {
      metric_type: metric_type,
      data: data,
      timestamp: Time.now.iso8601
    }
    
    request.body = JSON.generate(payload)
    
    begin
      response = http.request(request)
      
      if response.code == '200' || response.code == '201'
        puts "✅ Metrics sent successfully (HTTP #{response.code})"
        return true
      else
        puts "❌ API returned HTTP #{response.code}: #{response.body}"
        return false
      end
      
    rescue => e
      puts "❌ Error sending metrics: #{e.message}"
      puts "💡 Make sure the API server is running at #{api_base}"
      return false
    end
  end
end

# CLI interface
if __FILE__ == $0
  options = {
    api_token: ENV['API_TOKEN'],
    api_base: 'http://localhost:4567'
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: metrics.rb [options] COMMAND GEM_NAME"

    opts.on("-t", "--token TOKEN", "API token") do |token|
      options[:api_token] = token
    end

    opts.on("-a", "--api-base URL", "API base URL") do |url|
      options[:api_base] = url
    end

    opts.on("-h", "--help", "Show this help message") do
      puts opts
      puts ""
      puts "Commands:"
      puts "  benchmark GEM_NAME    Report benchmark results"
      puts "  cve GEM_NAME         Report CVE scan results"
      puts "  summary GEM_NAME     Generate and report summary"
      puts ""
      exit
    end
  end.parse!

  command = ARGV[0]
  gem_name = ARGV[1]

  if command.nil? || gem_name.nil?
    puts "Error: Command and gem name are required"
    puts "Usage: metrics.rb [options] COMMAND GEM_NAME"
    exit 1
  end

  reporter = MetricsReporter.new(
    api_token: options[:api_token],
    api_base: options[:api_base]
  )

  case command
  when 'benchmark'
    reporter.report_benchmark(gem_name)
  when 'cve'
    reporter.report_cve_scan(gem_name)
  when 'summary'
    reporter.generate_summary_report(gem_name)
  else
    puts "Error: Unknown command '#{command}'"
    puts "Available commands: benchmark, cve, summary"
    exit 1
  end
end 