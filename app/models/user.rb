require 'digest/sha1'

class User
  include Mongoid::Document
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  STANDARD_ROLE = :admin

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation, :role, :stream_ids
  
  field :login, :type => String
  field :email, :type => String
  field :name, :type => String
  field :password, :type => String
  field :password_confirmation, :type => String
  field :role, :type => String
  field :crypted_password, :type => String
  field :salt, :type => String
  field :remember_token, :type => String
  field :remember_token_expires_at
  field :stream_ids
  
#  has_and_belongs_to_many :streams
  references_and_referenced_in_many :streams, :inverse_of => :users
  references_and_referenced_in_many :favorite_streams, :class_name => "Stream"
  references_and_referenced_in_many :subscribed_streams, :class_name => "Stream"
  references_many :alerted_streams
#  has_and_belongs_to_many :favorite_streams, :join_table => "favorite_streams", :class_name => "Stream"
  #has_many :subscribed_streams, :dependent => :destroy
#  has_and_belongs_to_many :subscribed_streams, :join_table => "subscribed_streams", :class_name => "Stream"
#  has_many :alerted_streams, :dependent => :destroy

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
  
  def self.find_by_id(_id)
    find(:first, :conditions => {:_id => BSON::ObjectId(_id)})
  end
  
  def self.find_by_remember_token(token)
    find(:first, :conditions => {:remember_token => token})
  end
  
  def self.find_by_login(login)
    find(:first, :conditions => {:login => login})
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end
  
  def favorite_streams
    []
  end

  def roles
    role_symbols
  end
  
  def role_symbols
    [(role.blank? ? STANDARD_ROLE : role.to_sym)]
  end
  
  def valid_roles
    [:admin, :reader]
  end
end
