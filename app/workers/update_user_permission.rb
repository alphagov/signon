class UpdateUserPermission
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find_by_id(user_id)
    PermissionUpdater.new(user, user.applications_used).attempt
  end
end