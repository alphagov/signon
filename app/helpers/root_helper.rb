module RootHelper
  def gds_only_application_and_non_gds_user?
    @application.gds_only? && !current_user.belongs_to_gds?
  end

  def title
    if @application.blank? || gds_only_application_and_non_gds_user?
      "You don’t have permission to use this app."
    else
      "You don’t have permission to sign in to #{@application.name}."
    end
  end
end
