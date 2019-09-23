class User < ActiveRecord::Base
  has_many :permissions
end

class Permission < ActiveRecord::Base
  belongs_to :user
  belongs_to :application, class_name: "Doorkeeper::Application"
  serialize :permissions, Array

  validates_presence_of :application_id
  validates_presence_of :user_id
end

class SwapMagicEverythingPermissionsForRealOnes < ActiveRecord::Migration
  class ::Doorkeeper::Application
    has_many :permissions, dependent: :destroy
  end

  def up
    everything_app = ::Doorkeeper::Application.find_by_name("Everything")
    everything_app && everything_app.destroy

    User.all.each do |user|
      ::Doorkeeper::Application.all.each do |application|
        Permission.create(application: application, user: user, permissions: %w[signin])
      end
    end
  end

  def down
    Permission.all.delete_all
    everything_app = ::Doorkeeper::Application.create!(name: "Everything", uid: "not-a-real-app", secret: "does-not-have-a-secret", redirect_uri: "http://not-a-domain.com")
    User.all.each do |user|
      Permission.create(application: everything_app, user: user, permissions: %w[signin])
    end
  end
end
