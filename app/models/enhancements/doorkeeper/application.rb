class ::Doorkeeper::Application
  has_many :permissions, :dependent => :destroy
end