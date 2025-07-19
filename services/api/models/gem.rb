require 'sequel'

class GemRecord < Sequel::Model(:gems)
  plugin :validation_helpers
  plugin :json_serializer
  
  # Associations
  one_to_many :ratings, key: :gem_id, class: 'Rating'
  one_to_many :badges, key: :gem_id, class: 'Badge'
  
  # Validations
  def validate
    super
    validates_presence [:name, :version]
    validates_unique :name
    validates_format /^[a-zA-Z0-9_-]+$/, :name, message: 'must contain only letters, numbers, underscores, and hyphens'
    validates_format /^\d+\.\d+\.\d+$/, :version, message: 'must be in semantic versioning format (e.g., 1.0.0)'
    validates_integer :downloads, allow_nil: true
    validates_operator :>=, 0, :downloads, allow_nil: true
    validates_operator :>=, 0.0, :rating, allow_nil: true
    validates_operator :<=, 5.0, :rating, allow_nil: true
  end
  
  # Callbacks
  def before_create
    self.created_at ||= Time.now
    self.updated_at ||= Time.now
    self.downloads ||= 0
    self.rating ||= 0.0
  end
  
  def before_update
    self.updated_at = Time.now
  end
  
  # Instance methods
  def to_hash
    {
      id: id,
      name: name,
      version: version,
      description: description,
      homepage: homepage,
      license: license,
      downloads: downloads,
      rating: rating,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601,
      ratings_count: ratings.count,
      badges_count: badges.count
    }
  end
  
  def average_rating
    Rating.where(gem_id: id).avg(:score) || 0.0
  end
  
  def update_rating!
    update(rating: average_rating)
  end
  
  # Class methods
  def self.search(query)
    where(Sequel.like(:name, "%#{query}%") | Sequel.like(:description, "%#{query}%"))
  end
  
  def self.top_rated(limit = 10)
    order(:rating).reverse.limit(limit)
  end
  
  def self.most_downloaded(limit = 10)
    order(:downloads).reverse.limit(limit)
  end
  
  def self.recent(limit = 10)
    order(:created_at).reverse.limit(limit)
  end
end 