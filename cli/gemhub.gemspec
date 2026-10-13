# frozen_string_literal: true

require_relative "lib/gemhub/version"

Gem::Specification.new do |spec|
  spec.name = "gemhub"
  spec.version = GemHub::VERSION
  spec.authors = ["GemHub Team"]
  spec.email = ["team@gemhub.dev"]

  spec.summary = "CLI for GemHub - Ruby gem marketplace and development tools"
  spec.description = "GemHub CLI provides wizard-based gem creation, publishing, and integration with the GemHub marketplace"
  spec.homepage = "https://github.com/your-org/gemhub"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/your-org/gemhub"
  spec.metadata["changelog_uri"] = "https://github.com/your-org/gemhub/blob/main/CHANGELOG.md"

  # Container/source builds may not contain Git or a .git directory. Enumerate
  # the package's own source, and include bin/ so gem installation exposes the CLI.
  spec.files = Dir.chdir(__dir__) do
    Dir.glob(["lib/**/*", "bin/*", "README*", "LICENSE*"]).select do |file|
      File.file?(file)
    end.sort
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
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 2.25"
end 