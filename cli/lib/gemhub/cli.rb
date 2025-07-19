# frozen_string_literal: true

require "thor"

module GemHub
  # Main CLI class that handles all GemHub commands
  class CLI < Thor
    desc "wizard", "Interactive gem creator with name, license, and CI template setup"
    def wizard
      puts "🧙‍♂️ GemHub Gem Creation Wizard"
      puts "This will guide you through creating a new Ruby gem..."
      puts "✅ Wizard functionality will be implemented in full version"
    end

    desc "publish [GEM_NAME]", "Publish gem to GemHub marketplace and push git tag"
    def publish(gem_name = nil)
      puts "📦 Publishing #{gem_name || 'current gem'} to GemHub marketplace..."
      puts "✅ Publishing functionality will be implemented in full version"
    end

    desc "version", "Show GemHub CLI version"
    def version
      puts "GemHub CLI v#{GemHub::VERSION}"
    end
  end
end
