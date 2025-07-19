require_relative 'app'

puts "Seeding database with sample data..."

# Clear existing data
DB[:badges].delete
DB[:ratings].delete
DB[:gems].delete

# Create sample gems
gems = [
  {
    name: 'sinatra',
    version: '3.0.0',
    description: 'Classy web-development dressed in a DSL',
    homepage: 'http://sinatrarb.com/',
    license: 'MIT',
    downloads: 15000000,
    rating: 4.8
  },
  {
    name: 'rails',
    version: '7.1.0',
    description: 'Full-stack web application framework',
    homepage: 'https://rubyonrails.org/',
    license: 'MIT',
    downloads: 25000000,
    rating: 4.9
  },
  {
    name: 'sequel',
    version: '5.68.0',
    description: 'Database toolkit for Ruby',
    homepage: 'https://sequel.jeremyevans.net/',
    license: 'MIT',
    downloads: 8000000,
    rating: 4.7
  },
  {
    name: 'rspec',
    version: '3.12.0',
    description: 'BDD for Ruby',
    homepage: 'https://rspec.info/',
    license: 'MIT',
    downloads: 12000000,
    rating: 4.6
  },
  {
    name: 'puma',
    version: '6.3.0',
    description: 'A Ruby web server built for concurrency',
    homepage: 'https://puma.io/',
    license: 'BSD-3-Clause',
    downloads: 18000000,
    rating: 4.5
  }
]

gems.each do |gem_data|
  gem = GemRecord.create(gem_data.merge(
    created_at: Time.now,
    updated_at: Time.now
  ))
  puts "Created gem: #{gem.name}"
end

# Create sample ratings
ratings_data = [
  { score: 5, comment: 'Excellent gem, very well maintained', user_id: 'user1' },
  { score: 4, comment: 'Good documentation and easy to use', user_id: 'user2' },
  { score: 5, comment: 'Essential for Ruby development', user_id: 'user3' },
  { score: 4, comment: 'Solid performance and features', user_id: 'user4' },
  { score: 3, comment: 'Could use better error handling', user_id: 'user5' }
]

GemRecord.all.each do |gem|
  # Add 2-4 random ratings per gem
  rand(2..4).times do
    rating_data = ratings_data.sample.merge(gem_id: gem.id)
    Rating.create(rating_data)
  end
  puts "Added ratings for #{gem.name}"
end

# Create sample badges
badges_data = [
  { type: 'security', name: 'CVE-Free', description: 'No known security vulnerabilities' },
  { type: 'performance', name: 'Fast', description: 'High performance implementation' },
  { type: 'quality', name: 'Well-Tested', description: 'Comprehensive test coverage' },
  { type: 'popularity', name: 'Trending', description: 'Growing in popularity' },
  { type: 'maintenance', name: 'Actively Maintained', description: 'Regular updates and maintenance' },
  { type: 'security', name: 'Security Audit Passed', description: 'Passed security audit' },
  { type: 'performance', name: 'Optimized', description: 'Performance optimized' },
  { type: 'quality', name: 'Well-Documented', description: 'Excellent documentation' }
]

GemRecord.all.each do |gem|
  # Add 2-3 random badges per gem
  rand(2..3).times do
    badge_data = badges_data.sample.merge(gem_id: gem.id)
    Badge.create(badge_data)
  end
  puts "Added badges for #{gem.name}"
end

puts "Database seeded successfully!"
puts "Created #{GemRecord.count} gems, #{Rating.count} ratings, and #{Badge.count} badges" 