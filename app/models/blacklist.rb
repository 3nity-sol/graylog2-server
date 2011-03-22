class Blacklist
  include Mongoid::Document
  
  embeds_many :blacklisted_terms
  
  field :title, :type => String

  validates_presence_of :title
  
  def self.all_terms
    self.all.collect {|b|
      b.all_terms
    }.flatten
  end
  
  def all_terms
    blacklisted_terms.collect {|bt|
      bt.term
    }
  end
end
