class SupportedPermission < ActiveRecord::Base
  belongs_to :application, class_name: 'Doorkeeper::Application'

  validates_presence_of :name
  validate :signin_permission_name_not_changed

  attr_accessible :application_id, :name, :delegatable

  default_scope order(:name)
  scope :delegatable, -> { where(delegatable: true) }

private

  def signin_permission_name_not_changed
    return if new_record? || !name_changed?

    if name_change.first.downcase == 'signin'
      errors.add(:name, "of permission #{name_change.first} can't be changed")
    end
  end

end
