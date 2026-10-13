# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "rubygems"

root = File.expand_path("..", __dir__)
Dir.mktmpdir("gemhub-source-package") do |directory|
  %w[gemhub.gemspec lib bin].each do |entry|
    FileUtils.cp_r(File.join(root, "cli", entry), directory)
  end
  original_path = ENV["PATH"]
  begin
    ENV["PATH"] = directory # No external Git executable and no repository metadata.
    spec = Gem::Specification.load(File.join(directory, "gemhub.gemspec"))
    raise "Gemspec cannot load without Git" unless spec
    raise "Missing CLI executable" unless spec.executables == ["gemhub"]
    raise "Missing packaged executable" unless spec.files.include?("bin/gemhub")
    raise "Missing implementation" unless spec.files.include?("lib/gemhub/version.rb")
    raise "Unexpected repository files" unless spec.files.all? { |file| File.file?(File.join(directory, file)) }
    puts "PASS: source gemspec loads without Git and packages executable plus implementation"
  ensure
    ENV["PATH"] = original_path
  end
end
