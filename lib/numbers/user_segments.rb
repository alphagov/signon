class UserSegments
  module SegmentExtensions
    def licensing_user?
      has_access_to_licensing? and applications_with_signon_permission.size == 1
    end

    def active?
      suspended_at.nil?
    end

    private
    def applications_with_signon_permission
      permissions.select {|perm| perm.permissions.include?("signin") }
    end

    def has_access_to_licensing?
      applications_with_signon_permission.map { |p| p.application.name }.include?("Licensing")
    end
  end

  def initialize(users)
    @users = users.map { |u| u.extend(SegmentExtensions); u }
  end

  def licensing_users
    @users.select(&:licensing_user?)
  end

  def active_licensing_users
    licensing_users.select(&:active?)
  end

  def non_licensing_users
    @users.reject(&:licensing_user?)
  end

  def active_non_licensing_users
    non_licensing_users.select(&:active?)
  end
end
