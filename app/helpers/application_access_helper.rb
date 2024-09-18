module ApplicationAccessHelper
  def access_granted_description(application_id, user = current_user)
    application = Doorkeeper::Application.find_by(id: application_id)
    return nil unless application

    return "You have been granted access to #{application.name}." if user == current_user

    "#{user.name} has been granted access to #{application.name}."
  end
end
