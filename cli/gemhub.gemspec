# frozen_string_literal: true

require_relative "lib/gemhub/version"

Gem::Specification.new do |spec|
  spec.name = "gemhub"
  spec.version = GemHub::VERSION
  spec.authors = ["GemHub Team"]
  spec.email = ["team@gemhub.dev"]

  spec.summary = "CLI for GemHub - Ruby gem marketplace and development tools"
  spec.description = "GemHub CLI provides wizard-based gem creation, publishing, and integration with the GemHub marketplace"
  spec.homepage = "https://github.com/jadenfix/ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jadenfix/ruby"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "faraday", "~> 2.7"
  spec.add_dependency "json", "~> 2.6"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "pastel", "~> 0.8"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.57"
end
