# frozen_string_literal: true

require "thor"
require "tty-prompt"
require "pastel"
require "faraday"
require "json"

module GemHub
  # Main CLI class that handles all GemHub commands
  class CLI < Thor
    include Thor::Actions

    def initialize(*args)
      super
      @prompt = TTY::Prompt.new
      @pastel = Pastel.new
      @api_base = ENV.fetch("GEMHUB_API_URL", "http://localhost:4567")
    end

    desc "wizard", "Interactive gem creator with name, license, and CI template setup"
    long_desc <<-LONGDESC
      Launch an interactive wizard to create a new Ruby gem with:
      
      • Gem name and description
      • License selection (MIT, Apache, etc.)
      • CI/CD template (GitHub Actions, etc.)
      • Basic gem structure and files
      
      This command generates a complete gem skeleton ready for development.
    LONGDESC
    def wizard
      say_banner("GemHub Gem Creation Wizard")
      
      gem_data = collect_gem_info
      generate_gem_scaffold(gem_data)
      setup_ci_templates(gem_data) if gem_data[:ci_template]
      
      say_success("Gem '#{gem_data[:name]}' created successfully!")
      say_info("Next steps:")
      say_info("  cd #{gem_data[:name]}")
      say_info("  bundle install")
      say_info("  rake spec")
      say_info("  gemhub publish")
    end

    desc "publish [GEM_NAME]", "Publish gem to GemHub marketplace and push git tag"
    long_desc <<-LONGDESC
      Publish a gem to the GemHub marketplace and create a git tag.
      
      This command will:
      • Build the gem
      • POST to /gems API endpoint
      • Create and push a git tag
      • Display publication status
      
      If no gem name is provided, it will try to detect from the current directory.
    LONGDESC
    option :force, type: :boolean, desc: "Force publish even if gem exists"
    option :dry_run, type: :boolean, desc: "Show what would be published without actually doing it"
    def publish(gem_name = nil)
      gem_name ||= detect_gem_name
      
      unless gem_name
        say_error("Could not detect gem name. Please specify: gemhub publish GEM_NAME")
        exit 1
      end

      say_banner("Publishing #{gem_name} to GemHub")
      
      if options[:dry_run]
        say_info("DRY RUN: Would publish #{gem_name}")
        return
      end

      gem_data = build_gem_data(gem_name)
      publish_to_api(gem_data)
      create_git_tag(gem_data[:version])
      
      say_success("#{gem_name} v#{gem_data[:version]} published successfully!")
    end

    desc "list", "List gems from GemHub marketplace"
    option :limit, type: :numeric, default: 10, desc: "Number of gems to show"
    option :search, type: :string, desc: "Search term to filter gems"
    def list
      say_banner("GemHub Marketplace")
      
      gems = fetch_gems_from_api(options)
      
      if gems.empty?
        say_info("No gems found")
        return
      end

      gems.each do |gem|
        display_gem_info(gem)
      end
    end

    desc "info GEM_NAME", "Show detailed information about a gem"
    def info(gem_name)
      say_banner("Gem Information: #{gem_name}")
      
      gem_data = fetch_gem_info(gem_name)
      
      if gem_data
        display_detailed_gem_info(gem_data)
      else
        say_error("Gem '#{gem_name}' not found")
        exit 1
      end
    end

    desc "version", "Show GemHub CLI version"
    def version
      say "GemHub CLI v#{GemHub::VERSION}"
    end

    private

    def say_banner(text)
      say @pastel.cyan.bold("\n=== #{text} ===\n")
    end

    def say_success(text)
      say @pastel.green("✓ #{text}")
    end

    def say_error(text)
      say @pastel.red("✗ #{text}")
    end

    def say_info(text)
      say @pastel.blue("ℹ #{text}")
    end

    def collect_gem_info
      gem_data = {}
      
      gem_data[:name] = @prompt.ask("Gem name:", required: true) do |q|
        q.validate(/\A[a-z][a-z0-9_]*\z/, "Gem name must be lowercase with underscores")
      end
      
      gem_data[:description] = @prompt.ask("Gem description:", required: true)
      
      gem_data[:author] = @prompt.ask("Author name:", default: git_user_name)
      gem_data[:email] = @prompt.ask("Author email:", default: git_user_email)
      
      license_choices = %w[MIT Apache-2.0 GPL-3.0 BSD-3-Clause Unlicense]
      gem_data[:license] = @prompt.select("Choose a license:", license_choices, default: "MIT")
      
      gem_data[:ci_template] = @prompt.yes?("Set up GitHub Actions CI?")
      
      gem_data[:version] = "0.1.0"
      
      gem_data
    end

    def generate_gem_scaffold(gem_data)
      say_info("Generating gem scaffold...")
      
      gem_dir = gem_data[:name]
      
      # Create directory structure
      empty_directory(gem_dir)
      empty_directory("#{gem_dir}/lib")
      empty_directory("#{gem_dir}/lib/#{gem_data[:name]}")
      empty_directory("#{gem_dir}/spec")
      empty_directory("#{gem_dir}/bin")
      
      # Generate files
      create_gemspec(gem_data)
      create_main_lib_file(gem_data)
      create_version_file(gem_data)
      create_readme(gem_data)
      create_license_file(gem_data)
      create_gemfile(gem_data)
      create_rakefile(gem_data)
      create_spec_files(gem_data)
    end

    def setup_ci_templates(gem_data)
      say_info("Setting up GitHub Actions...")
      
      empty_directory("#{gem_data[:name]}/.github")
      empty_directory("#{gem_data[:name]}/.github/workflows")
      
      create_file("#{gem_data[:name]}/.github/workflows/ci.yml", github_actions_template)
    end

    def create_gemspec(gem_data)
      content = <<~GEMSPEC
        # frozen_string_literal: true

        require_relative "lib/#{gem_data[:name]}/version"

        Gem::Specification.new do |spec|
          spec.name = "#{gem_data[:name]}"
          spec.version = #{gem_data[:name].split('_').map(&:capitalize).join}::VERSION
          spec.authors = ["#{gem_data[:author]}"]
          spec.email = ["#{gem_data[:email]}"]

          spec.summary = "#{gem_data[:description]}"
          spec.description = "#{gem_data[:description]}"
          spec.homepage = "https://github.com/#{git_user_name}/#{gem_data[:name]}"
          spec.license = "#{gem_data[:license]}"
          spec.required_ruby_version = ">= 3.0.0"

          spec.metadata["homepage_uri"] = spec.homepage
          spec.metadata["source_code_uri"] = spec.homepage
          spec.metadata["changelog_uri"] = "\#{spec.homepage}/blob/main/CHANGELOG.md"

          spec.files = Dir.chdir(__dir__) do
            `git ls-files -z`.split("\\x0").reject do |f|
              (File.expand_path(f) == __FILE__) ||
                f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
            end
          end
          spec.bindir = "exe"
          spec.executables = spec.files.grep(%r{\\Aexe/}) { |f| File.basename(f) }
          spec.require_paths = ["lib"]

          # Dependencies can be added here
          # spec.add_dependency "example-gem", "~> 1.0"
          
          spec.add_development_dependency "bundler", "~> 2.0"
          spec.add_development_dependency "rake", "~> 13.0"
          spec.add_development_dependency "rspec", "~> 3.12"
        end
      GEMSPEC
      
      create_file("#{gem_data[:name]}/#{gem_data[:name]}.gemspec", content)
    end

    def create_main_lib_file(gem_data)
      module_name = gem_data[:name].split('_').map(&:capitalize).join
      
      content = <<~RUBY
        # frozen_string_literal: true

        require_relative "#{gem_data[:name]}/version"

        # Main module for #{gem_data[:name]}
        module #{module_name}
          class Error < StandardError; end
          
          # Your gem code goes here
          def self.hello
            "Hello from #{gem_data[:name]}!"
          end
        end
      RUBY
      
      create_file("#{gem_data[:name]}/lib/#{gem_data[:name]}.rb", content)
    end

    def create_version_file(gem_data)
      module_name = gem_data[:name].split('_').map(&:capitalize).join
      
      content = <<~RUBY
        # frozen_string_literal: true

        module #{module_name}
          VERSION = "#{gem_data[:version]}"
        end
      RUBY
      
      create_file("#{gem_data[:name]}/lib/#{gem_data[:name]}/version.rb", content)
    end

    def create_readme(gem_data)
      content = <<~MARKDOWN
        # #{gem_data[:name].split('_').map(&:capitalize).join}

        #{gem_data[:description]}

        ## Installation

        Add this line to your application's Gemfile:

        ```ruby
        gem '#{gem_data[:name]}'
        ```

        And then execute:

            $ bundle install

        Or install it yourself as:

            $ gem install #{gem_data[:name]}

        ## Usage

        ```ruby
        require '#{gem_data[:name]}'

        #{gem_data[:name].split('_').map(&:capitalize).join}.hello
        # => "Hello from #{gem_data[:name]}!"
        ```

        ## Development

        After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

        To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

        ## Contributing

        Bug reports and pull requests are welcome on GitHub at https://github.com/#{git_user_name}/#{gem_data[:name]}.

        ## License

        The gem is available as open source under the terms of the [#{gem_data[:license]} License](https://opensource.org/licenses/#{gem_data[:license]}).
      MARKDOWN
      
      create_file("#{gem_data[:name]}/README.md", content)
    end

    def create_license_file(gem_data)
      # Simplified license content - in a real implementation, you'd have templates for each license
      content = case gem_data[:license]
                when "MIT"
                  mit_license_content(gem_data)
                else
                  "#{gem_data[:license]} License - Content to be implemented"
                end
      
      create_file("#{gem_data[:name]}/LICENSE.txt", content)
    end

    def create_gemfile(gem_data)
      content = <<~RUBY
        # frozen_string_literal: true

        source "https://rubygems.org"

        # Specify your gem's dependencies in #{gem_data[:name]}.gemspec
        gemspec

        gem "rake", "~> 13.0"
        gem "rspec", "~> 3.0"
      RUBY
      
      create_file("#{gem_data[:name]}/Gemfile", content)
    end

    def create_rakefile(gem_data)
      content = <<~RUBY
        # frozen_string_literal: true

        require "bundler/gem_tasks"
        require "rspec/core/rake_task"

        RSpec::Core::RakeTask.new(:spec)

        task default: :spec
      RUBY
      
      create_file("#{gem_data[:name]}/Rakefile", content)
    end

    def create_spec_files(gem_data)
      module_name = gem_data[:name].split('_').map(&:capitalize).join
      
      spec_helper_content = <<~RUBY
        # frozen_string_literal: true

        require "#{gem_data[:name]}"

        RSpec.configure do |config|
          # Enable flags like --only-failures and --next-failure
          config.example_status_persistence_file_path = ".rspec_status"

          # Disable RSpec exposing methods globally on `Module` and `main`
          config.disable_monkey_patching!

          config.expect_with :rspec do |c|
            c.syntax = :expect
          end
        end
      RUBY
      
      main_spec_content = <<~RUBY
        # frozen_string_literal: true

        RSpec.describe #{module_name} do
          it "has a version number" do
            expect(#{module_name}::VERSION).not_to be nil
          end

          it "says hello" do
            expect(#{module_name}.hello).to eq("Hello from #{gem_data[:name]}!")
          end
        end
      RUBY
      
      create_file("#{gem_data[:name]}/spec/spec_helper.rb", spec_helper_content)
      create_file("#{gem_data[:name]}/spec/#{gem_data[:name]}_spec.rb", main_spec_content)
    end

    def github_actions_template
      <<~YAML
        name: CI

        on:
          push:
            branches: [ main ]
          pull_request:
            branches: [ main ]

        jobs:
          test:
            runs-on: ubuntu-latest
            strategy:
              matrix:
                ruby-version: ['3.0', '3.1', '3.2', '3.3']

            steps:
            - uses: actions/checkout@v4
            - name: Set up Ruby ${{ matrix.ruby-version }}
              uses: ruby/setup-ruby@v1
              with:
                ruby-version: ${{ matrix.ruby-version }}
                bundler-cache: true
            - name: Run tests
              run: bundle exec rake
      YAML
    end

    def mit_license_content(gem_data)
      current_year = Time.now.year
      <<~LICENSE
        MIT License

        Copyright (c) #{current_year} #{gem_data[:author]}

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
      LICENSE
    end

    def detect_gem_name
      gemspec_files = Dir.glob("*.gemspec")
      return nil if gemspec_files.empty?
      
      File.basename(gemspec_files.first, ".gemspec")
    end

    def build_gem_data(gem_name)
      gemspec_file = "#{gem_name}.gemspec"
      unless File.exist?(gemspec_file)
        say_error("Gemspec file not found: #{gemspec_file}")
        exit 1
      end

      spec = Gem::Specification.load(gemspec_file)
      {
        name: spec.name,
        version: spec.version.to_s,
        description: spec.description,
        author: spec.authors.first,
        email: spec.email.first,
        homepage: spec.homepage
      }
    end

    def publish_to_api(gem_data)
      say_info("Publishing to GemHub API...")
      
      conn = Faraday.new(url: @api_base) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end

      response = conn.post("/gems") do |req|
        req.headers["Authorization"] = "Bearer #{ENV['GEMHUB_API_TOKEN']}" if ENV["GEMHUB_API_TOKEN"]
        req.body = gem_data
      end

      if response.success?
        say_success("Published to API successfully")
      else
        say_error("API publish failed: #{response.status} - #{response.body}")
        exit 1
      end
    rescue Faraday::Error => e
      say_error("API connection failed: #{e.message}")
      exit 1
    end

    def create_git_tag(version)
      say_info("Creating git tag v#{version}...")
      
      system("git add -A")
      system("git commit -m 'Release v#{version}'") 
      system("git tag v#{version}")
      
      if @prompt.yes?("Push tag to remote?")
        system("git push origin main")
        system("git push origin v#{version}")
        say_success("Tag pushed to remote")
      end
    end

    def fetch_gems_from_api(options)
      conn = Faraday.new(url: @api_base) do |faraday|
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end

      params = { limit: options[:limit] }
      params[:search] = options[:search] if options[:search]

      response = conn.get("/gems", params)
      
      if response.success?
        response.body
      else
        say_error("Failed to fetch gems: #{response.status}")
        []
      end
    rescue Faraday::Error => e
      say_error("API connection failed: #{e.message}")
      []
    end

    def fetch_gem_info(gem_name)
      conn = Faraday.new(url: @api_base) do |faraday|
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end

      response = conn.get("/gems/#{gem_name}")
      
      if response.success?
        response.body
      else
        nil
      end
    rescue Faraday::Error
      nil
    end

    def display_gem_info(gem)
      say "\n#{@pastel.cyan.bold(gem['name'])} (#{gem['version']})"
      say "  #{gem['description']}" if gem['description']
      say "  Author: #{gem['author']}" if gem['author']
      say "  Downloads: #{gem['downloads']}" if gem['downloads']
    end

    def display_detailed_gem_info(gem)
      say "Name: #{@pastel.cyan.bold(gem['name'])}"
      say "Version: #{gem['version']}"
      say "Description: #{gem['description']}"
      say "Author: #{gem['author']}"
      say "Email: #{gem['email']}"
      say "Homepage: #{gem['homepage']}" if gem['homepage']
      say "License: #{gem['license']}" if gem['license']
      say "Downloads: #{gem['downloads']}" if gem['downloads']
      say "Created: #{gem['created_at']}" if gem['created_at']
    end

    def git_user_name
      `git config user.name`.chomp rescue "Developer"
    end

    def git_user_email
      `git config user.email`.chomp rescue "developer@example.com"
    end
  end
end 