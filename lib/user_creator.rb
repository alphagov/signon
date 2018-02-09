require 'plek'

class UserCreator
  attr_reader :user

  def initialize(name, email, application_names)
    @name = name.dup
    @email = email.dup
    @application_names = application_names.dup
  end

  def applications
    @applications ||= extract_applications_from_names
  end

  def create_user!
    @user = User.invite!(name: name, email: email)
    grant_requested_signin_permissions
    grant_default_permissions
  end

  def invitation_url
    "#{Plek.new.external_url_for('signon')}/users/invitation/accept?invitation_token=#{user.raw_invitation_token}"
  end

private

  attr_reader :name, :email, :application_names

  def extract_applications_from_names
    (application_names.split(',')).uniq.map do |application_name|
      Doorkeeper::Application.find_by_name!(application_name)
    end
  end

  def grant_requested_signin_permissions
    applications.each do |application|
      user.grant_application_permission(application, 'signin')
    end
  end

  def grant_default_permissions
    SupportedPermission.default.each do |default_permission|
      user.grant_permission(default_permission)
    end
  end
end
