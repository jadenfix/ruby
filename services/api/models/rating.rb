require 'sequel'

class Rating < Sequel::Model(:ratings)
  plugin :validation_helpers
  plugin :json_serializer
  
  # Associations
  many_to_one :gem_record, key: :gem_id, class: 'GemRecord'
  
  # Validations
  def validate
    super
    validates_presence [:gem_id, :score]
    validates_integer :score
    validates_operator :>=, 1, :score, message: 'must be at least 1'
    validates_operator :<=, 5, :score, message: 'must be at most 5'
    validates_presence :user_id, message: 'user_id is required'
  end
  
  # Callbacks
  def before_create
    self.created_at ||= Time.now
  end
  
  def after_create
    gem_record&.update_rating!
  end
  
  def after_update
    gem_record&.update_rating!
  end
  
  def after_destroy
    gem_record&.update_rating!
  end
  
  # Instance methods
  def to_hash
    {
      id: id,
      gem_id: gem_id,
      score: score,
      comment: comment,
      user_id: user_id,
      created_at: created_at&.iso8601
    }
  end
  
  # Class methods
  def self.for_gem(gem_id)
    where(gem_id: gem_id).order(:created_at).reverse
  end
  
  def self.average_for_gem(gem_id)
    where(gem_id: gem_id).avg(:score) || 0.0
  end
  
  def self.count_for_gem(gem_id)
    where(gem_id: gem_id).count
  end
end 