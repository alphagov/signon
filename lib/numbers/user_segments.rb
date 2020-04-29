module Numbers
  class UserSegments
    module SegmentExtensions
      def licensing_user?
        application_permissions.count == 1 && has_access_to?(Doorkeeper::Application.find_by(name: "Licensing"))
      end

      def active?
        suspended_at.nil?
      end
    end

    def initialize(users)
      @users = users.map do |user|
        user.extend(SegmentExtensions)
        user
      end
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
end
