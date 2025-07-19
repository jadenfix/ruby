require 'sequel'

class Badge < Sequel::Model(:badges)
  plugin :validation_helpers
  plugin :json_serializer
  
  # Associations
  many_to_one :gem_record, key: :gem_id, class: 'GemRecord'
  
  # Validations
  def validate
    super
    validates_presence [:gem_id, :type, :name]
    validates_includes ['security', 'performance', 'quality', 'popularity', 'maintenance'], :type, message: 'must be one of: security, performance, quality, popularity, maintenance'
  end
  
  # Callbacks
  def before_create
    self.created_at ||= Time.now
  end
  
  # Instance methods
  def to_hash
    {
      id: id,
      gem_id: gem_id,
      type: type,
      name: name,
      description: description,
      created_at: created_at&.iso8601
    }
  end
  
  # Class methods
  def self.for_gem(gem_id)
    where(gem_id: gem_id).order(:created_at).reverse
  end
  
  def self.by_type(type)
    where(type: type).order(:created_at).reverse
  end
  
  def self.recent(limit = 10)
    order(:created_at).reverse.limit(limit)
  end
  
  # Badge types and their descriptions
  BADGE_TYPES = {
    'security' => 'Security-related badges (e.g., CVE-free, security audit passed)',
    'performance' => 'Performance-related badges (e.g., fast, optimized)',
    'quality' => 'Quality-related badges (e.g., well-tested, documented)',
    'popularity' => 'Popularity-related badges (e.g., trending, widely used)',
    'maintenance' => 'Maintenance-related badges (e.g., actively maintained, recent updates)'
  }
  
  def self.available_types
    BADGE_TYPES.keys
  end
end 