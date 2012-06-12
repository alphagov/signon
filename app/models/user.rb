require 'digest/md5'

class User < ActiveRecord::Base
  self.include_root_in_json = true

  devise :database_authenticatable, :recoverable, :trackable,
         :validatable, :timeoutable, :lockable,                # devise core model extensions
         :invitable,    # in devise_invitable gem
         :suspendable,  # in signonotron2/lib/devise/models/suspendable.rb
         :strengthened  # in signonotron2/lib/devise/models/strengthened.rb

  attr_accessible :uid, :name, :email, :password, :password_confirmation
  attr_readonly :uid

  validates :name, presence: true

  has_many :authorisations, :class_name => 'Doorkeeper::AccessToken', :foreign_key => :resource_owner_id
  has_many :permissions

  before_create :generate_uid

  def generate_uid
    self.uid = UUID.generate
  end

  def to_sensible_json
    sensible_permissions = {}
    self.permissions.each do |permission|
      sensible_permissions[permission.application.name] = permission.permissions
    end
    { user: { uid: uid, name: name, email: email, permissions: sensible_permissions } }.to_json
  end

  def gravatar_url(opts = {})
    opts.symbolize_keys!
    qs = opts.select { |k, v| k == :s }.collect { |k, v| "#{k}=#{Rack::Utils.escape(v)}" }.join('&')
    qs = "?" + qs unless qs == ""

    "#{opts[:ssl] ? 'https://secure' : 'http://www'}.gravatar.com/avatar/" +
      Digest::MD5.hexdigest(email.downcase) + qs
  end
end
