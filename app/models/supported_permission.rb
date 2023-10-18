class SupportedPermission < ApplicationRecord
  SIGNIN_NAME = "signin".freeze

  belongs_to :application, class_name: "Doorkeeper::Application"
  has_many :user_application_permissions, dependent: :destroy, inverse_of: :supported_permission

  validates :name, presence: true, uniqueness: { scope: :application_id }
  validates :application, presence: true
  validate :signin_permission_name_not_changed

  default_scope { order(:name) }
  scope :delegatable, -> { where(delegatable: true) }
  scope :grantable_from_ui, -> { where(grantable_from_ui: true) }
  scope :default, -> { where(default: true) }
  scope :signin, -> { where(name: SIGNIN_NAME) }

  def signin?
    name.try(:downcase) == SIGNIN_NAME
  end

private

  def signin_permission_name_not_changed
    return if new_record? || !name_changed?

    if name_change.first.casecmp(SIGNIN_NAME).zero?
      errors.add(:name, "of permission #{name_change.first} can't be changed")
    end
  end
end
