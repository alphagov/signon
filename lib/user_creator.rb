require 'plek'

class UserCreator
  attr_reader :user

  def initialize(name, email, application_names)
    @name = name.dup
    @email = email.dup
    @application_names = application_names.dup
  end

  def applications
    @applications ||= (extract_applications_from_names + default_applications).uniq
  end

  def create_user!
    @user = User.invite!(name: name, email: email)
    applications.each do |application|
      @user.grant_application_permission(application, 'signin')
    end
  end

  def invitation_url
    "#{Plek.current.find('signon')}/users/invitation/accept?invitation_token=#{user.raw_invitation_token}"
  end

private

  attr_reader :name, :email, :application_names

  def extract_applications_from_names
    (application_names.split(',')).uniq.map do |application_name|
      Doorkeeper::Application.find_by_name!(application_name)
    end
  end

  def default_applications
    ['support'].map { |default_app| ::Doorkeeper::Application.find_by(name: default_app) }.compact
  end
end
