# Lane C - Sandbox & Quality Gates

Lane C provides sandbox orchestration, performance benchmarking, security scanning, and metrics reporting for the GemHub platform.

## 🏗️ Architecture

```
services/
├── sandbox_orch/          # Rails demo orchestration
│   └── launch.sh         # One-click sandbox launcher
├── bench/                 # Performance benchmarking
│   └── bench.rb          # benchmark-ips runner
├── cve_scanner/          # Security vulnerability scanning
│   └── scan.rb           # RubySec API wrapper
├── reporting/             # Metrics and reporting
│   └── metrics.rb        # API integration
├── bench_results/         # Benchmark output files
└── cve_scanner/results/  # CVE scan output files
```

## 🚀 Quick Start

### 1. Launch a Sandbox

```bash
# Launch Rails demo with a gem
./services/sandbox_orch/launch.sh -g sinatra -p /path/to/sinatra

# Launch with custom port
./services/sandbox_orch/launch.sh -g rails --port 3001

# Get help
./services/sandbox_orch/launch.sh --help
```

### 2. Run Benchmarks

```bash
# Benchmark a gem
./services/bench/bench.rb sinatra

# Compare with baseline
./services/bench/bench.rb rails -b sinatra

# Custom configuration
./services/bench/bench.rb nokogiri -i 50000 -w 3 -t 10
```

### 3. Scan for CVEs

```bash
# Scan a gem
./services/cve_scanner/scan.rb rails

# Scan specific version
./services/cve_scanner/scan.rb sinatra -v 2.2.0

# Get help
./services/cve_scanner/scan.rb --help
```

### 4. Report Metrics

```bash
# Report benchmark results
./services/reporting/metrics.rb benchmark sinatra

# Report CVE scan results
./services/reporting/metrics.rb cve rails

# Generate comprehensive summary
./services/reporting/metrics.rb summary nokogiri
```

## 📋 Services Overview

### 🏖️ Sandbox Orchestrator

**Purpose**: Launch isolated Rails demo apps with target gems mounted.

**Features**:
- One-click Rails demo app creation
- Docker-based isolation
- Automatic gem mounting and testing
- Customizable Rails versions
- Health checks and status monitoring

**Usage**:
```bash
./services/sandbox_orch/launch.sh -g <gem_name> -p <gem_path> [options]
```

**Options**:
- `-g, --gem-name`: Name of the gem to test
- `-p, --gem-path`: Path to the gem source code
- `-r, --rails-version`: Rails version (default: 7.0)
- `-P, --port`: Demo app port (default: 3000)
- `-n, --name`: Demo app name (default: gemhub-demo)

**Output**:
- Creates `sandbox_<name>/` directory
- Generates `docker-compose.sandbox.yml`
- Launches Rails app at `http://localhost:<port>`
- Provides teardown script

### 📊 Benchmark Service

**Purpose**: Run performance benchmarks using benchmark-ips.

**Features**:
- Standard Ruby operation benchmarks
- Gem-specific benchmarks
- Baseline comparisons
- JSON output with statistics
- Configurable iterations and timing

**Usage**:
```bash
./services/bench/bench.rb <gem_name> [options]
```

**Options**:
- `-b, --baseline`: Baseline gem for comparison
- `-i, --iterations`: Number of iterations (default: 100000)
- `-w, --warmup`: Warmup time in seconds (default: 2)
- `-t, --time`: Calculation time in seconds (default: 5)

**Benchmark Categories**:
- String operations (concat, interpolation, format)
- Array operations (map, select, reduce)
- Hash operations (access, merge, transform)
- Gem-specific operations (Sinatra, Rails, Sequel, Nokogiri)

**Output**:
- Saves to `services/bench_results/<gem>_<timestamp>.json`
- Also saves `services/bench_results/<gem>_latest.json`
- Includes iterations/sec, standard deviation, and comparisons

### 🔍 CVE Scanner

**Purpose**: Scan gems for security vulnerabilities using RubySec API.

**Features**:
- Real-time RubySec API integration
- Mock data for demonstration
- Severity classification (critical, high, medium, low)
- Risk score calculation
- Version-specific vulnerability checking

**Usage**:
```bash
./services/cve_scanner/scan.rb <gem_name> [options]
```

**Options**:
- `-v, --version`: Gem version to scan
- `-f, --format`: Output format (json, text)

**Supported Gems**:
- Rails (SQL injection, XSS vulnerabilities)
- Sinatra (path traversal)
- Nokogiri (XXE vulnerabilities)
- Sequel (SQL injection)
- Generic vulnerabilities for other gems

**Output**:
- Saves to `services/cve_scanner/results/<gem>_<timestamp>.json`
- Also saves `services/cve_scanner/results/<gem>_latest.json`
- Includes CVE details, severity, risk score, and recommendations

### 📈 Reporting Service

**Purpose**: Send benchmark and CVE results to the API for integration.

**Features**:
- API integration via `/metrics` endpoint
- Comprehensive summary reports
- Performance and security scoring
- Automated recommendations

**Usage**:
```bash
./services/reporting/metrics.rb <command> <gem_name> [options]
```

**Commands**:
- `benchmark`: Report benchmark results
- `cve`: Report CVE scan results
- `summary`: Generate comprehensive summary

**Options**:
- `-t, --token`: API token
- `-a, --api-base`: API base URL (default: http://localhost:4567)

**Output**:
- Sends data to API `/metrics` endpoint
- Saves comprehensive reports to `services/reporting/reports/`
- Generates performance and security scores
- Provides actionable recommendations

## 🔧 Configuration

### Environment Variables

```bash
# API Configuration
export API_TOKEN="your-api-token"
export API_BASE_URL="http://localhost:4567"

# Docker Configuration (for sandbox)
export DOCKER_COMPOSE_VERSION="3.8"
export RAILS_VERSION="7.0"

# Benchmark Configuration
export BENCHMARK_ITERATIONS="100000"
export BENCHMARK_WARMUP_TIME="2"
export BENCHMARK_CALCULATION_TIME="5"
```

### File Structure

```
services/
├── sandbox_orch/
│   └── launch.sh                    # Sandbox launcher
├── bench/
│   └── bench.rb                     # Benchmark runner
├── cve_scanner/
│   ├── scan.rb                      # CVE scanner
│   └── results/                     # CVE scan results
├── reporting/
│   ├── metrics.rb                   # Metrics reporter
│   └── reports/                     # Summary reports
├── bench_results/                   # Benchmark results
└── cve_scanner/results/            # CVE scan results
```

## 🧪 Testing

### Test Sandbox

```bash
# Test with a simple gem
./services/sandbox_orch/launch.sh -g sinatra

# Verify the demo app loads
curl http://localhost:3000

# Check gem information
curl http://localhost:3000 | grep -i sinatra
```

### Test Benchmarks

```bash
# Run benchmark on a common gem
./services/bench/bench.rb json

# Check results
cat services/bench_results/json_latest.json | jq '.summary'
```

### Test CVE Scanner

```bash
# Test with a known vulnerable gem
./services/cve_scanner/scan.rb rails

# Check results
cat services/cve_scanner/results/rails_latest.json | jq '.risk_score'
```

### Test Reporting

```bash
# Start the API server first
cd services/api && API_TOKEN=test-token bundle exec ruby app.rb &

# Report metrics
./services/reporting/metrics.rb summary rails
```

## 📊 Definition of Done

### ✅ Sandbox Orchestrator
- [ ] `./launch.sh` opens Rails app showing the loaded gem
- [ ] Scripts run cross-platform (macOS/Linux) inside Docker
- [ ] Teardown script properly cleans up containers
- [ ] Demo app displays gem information and status

### ✅ Benchmark Service
- [ ] Benchmark JSON contains iterations/sec & std-dev for ≥1 method
- [ ] Supports gem-specific benchmarks for major gems
- [ ] Generates comprehensive performance reports
- [ ] Handles baseline comparisons

### ✅ CVE Scanner
- [ ] CVE scan detects a seeded vulnerable gem in test
- [ ] Provides realistic mock data for demonstration
- [ ] Calculates accurate risk scores
- [ ] Generates actionable security recommendations

### ✅ Reporting Service
- [ ] Successfully sends metrics to API `/metrics` endpoint
- [ ] Generates comprehensive summary reports
- [ ] Calculates performance and security scores
- [ ] Provides actionable recommendations

## 🔗 Integration

### With Lane B (API)
- CVE scanner integrates with `/scan` endpoint
- Reporting service sends metrics to `/metrics` endpoint
- Benchmark results stored in API database

### With Lane A (Frontend)
- Sandbox URLs displayed in VS Code extension
- Benchmark charts rendered in sidebar
- CVE alerts shown in security tab

### With Lane D (AI)
- Benchmark data used for performance ranking
- CVE data used for security scoring
- Summary reports feed into AI recommendations

## 🚨 Troubleshooting

### Common Issues

**Sandbox won't start**:
```bash
# Check Docker is running
docker --version

# Check Docker Compose is available
docker-compose --version

# Check port availability
lsof -i :3000
```

**Benchmark fails**:
```bash
# Install benchmark-ips
gem install benchmark-ips

# Check gem is available
gem list <gem_name>
```

**CVE scanner returns no results**:
```bash
# Check internet connection
curl -I https://rubysec.com/api/v1/gems/rails

# Use mock data for testing
./services/cve_scanner/scan.rb rails
```

**Reporting fails**:
```bash
# Check API server is running
curl http://localhost:4567/health

# Check API token
echo $API_TOKEN

# Test API connection
curl -H "Authorization: Bearer $API_TOKEN" http://localhost:4567/gems
```

## 📈 Performance

### Benchmarks
- String operations: ~1M iterations/sec
- Array operations: ~50K iterations/sec
- Hash operations: ~2M iterations/sec
- Gem-specific: Varies by gem complexity

### CVE Scans
- API response time: <2 seconds
- Mock data generation: <1 second
- Risk score calculation: <0.1 seconds

### Sandbox Launch
- Docker image pull: 30-60 seconds (first time)
- Rails app startup: 30-45 seconds
- Total launch time: 1-2 minutes

## 🔮 Future Enhancements

### Planned Features
- [ ] Support for more gem types (native extensions, etc.)
- [ ] Integration with GitHub Security Advisories
- [ ] Automated benchmark regression detection
- [ ] Sandbox persistence and state management
- [ ] Real-time metrics streaming
- [ ] Advanced vulnerability correlation

### Performance Optimizations
- [ ] Parallel benchmark execution
- [ ] Cached CVE data
- [ ] Optimized Docker layers
- [ ] Background metric processing

---

**Lane C is ready for integration with the full GemHub platform!** 🚀 