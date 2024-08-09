require "doorkeeper/orm/active_record/application"

class Doorkeeper::Application < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
  has_many :supported_permissions, dependent: :destroy
  has_many :event_logs, class_name: "EventLog"

  default_scope { not_retired.ordered_by_name }

  scope :ordered_by_name, -> { order("oauth_applications.name") }
  scope :support_push_updates, -> { where(supports_push_updates: true) }
  scope :retired, -> { where(retired: true) }
  scope :not_retired, -> { where(retired: false) }
  scope :api_only, -> { where(api_only: true) }
  scope :not_api_only, -> { where(api_only: false) }
  scope :with_home_uri, -> { where.not(home_uri: nil).where.not(home_uri: "") }
  scope :can_signin, ->(user) { with_signin_permission_for(user) }
  scope :with_signin_delegatable,
        lambda {
          joins(:supported_permissions)
            .merge(SupportedPermission.signin)
            .merge(SupportedPermission.delegatable)
        }
  scope :with_signin_permission_for,
        lambda { |user|
          joins(supported_permissions: :user_application_permissions)
            .where(user_application_permissions: { user: })
            .merge(SupportedPermission.signin)
        }
  scope :without_signin_permission_for,
        lambda { |user|
          excluded_app_ids = with_signin_permission_for(user).map(&:id)
          where.not(id: excluded_app_ids)
        }

  after_create :create_signin_supported_permission
  after_save :create_user_update_supported_permission

  def self.policy_class
    ApplicationPolicy
  end

  def signin_permission
    supported_permissions.signin.first
  end

  def sorted_supported_permissions_grantable_from_ui(include_signin: true, only_delegatable: false)
    permissions = supported_permissions.grantable_from_ui
    permissions = permissions.excluding_signin unless include_signin
    permissions = permissions.delegatable if only_delegatable

    SupportedPermission.sort_with_signin_first(permissions)
  end

  def has_non_signin_permissions_grantable_from_ui?
    (supported_permissions.grantable_from_ui - [signin_permission]).any?
  end

  def has_delegatable_non_signin_permissions_grantable_from_ui?
    (supported_permissions.delegatable.grantable_from_ui - [signin_permission]).any?
  end

  def has_non_delegatable_non_signin_permissions_grantable_from_ui?
    (supported_permissions.grantable_from_ui.where(delegatable: false) - [signin_permission]).any?
  end

  def url_without_path
    parsed_url = URI.parse(redirect_uri)
    "#{parsed_url.scheme}://#{parsed_url.host}:#{parsed_url.port}"
  end

  def gds_only?
    [
      "Collections Publisher",
      "Publisher",
      "Service Manual Publisher",
    ].include?(name)
  end

  def redirect_uri
    substituted_uri(self[:redirect_uri])
  end

  def home_uri
    substituted_uri(self[:home_uri])
  end

private

  def substituted_uri(uri)
    return if uri.blank?

    uri_pattern = Rails.configuration.oauth_apps_uri_sub_pattern
    uri_sub = Rails.configuration.oauth_apps_uri_sub_replacement

    if uri_pattern.present? && uri_sub.present?
      uri.sub(uri_pattern, uri_sub)
    else
      uri
    end
  end

  def create_signin_supported_permission
    supported_permissions.delegatable.signin.create!
  end

  def create_user_update_supported_permission
    supported_permissions.where(name: "user_update_permission", grantable_from_ui: false).first_or_create! if supports_push_updates?
  end
end
