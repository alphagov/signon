class SupportedPermission < ActiveRecord::Base
  belongs_to :application, class_name: 'Doorkeeper::Application'

  validates_presence_of :name
  validate :freeze_signin_permission_name, if: :name_changed?

  attr_accessible :application_id, :name, :delegatable

private

  def freeze_signin_permission_name
    if %w(signin Signin).include?(name_change.first)
      errors.add(:name, "of permission #{name_change.first} can't be changed")
    end
  end

end
