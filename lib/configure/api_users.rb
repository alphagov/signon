module Configure
  class ApiUsers
    def initialize(namespace:, resource_name_prefix:)
      @namespace = namespace
      @name_prefix = resource_name_prefix
    end

    def configure!(api_users)
      api_users.each do |api_user|
        email = [namespace, "#{api_user.fetch('slug')}@digital.cabinet-office.gov.uk"].compact.join("-")
        find_or_create_api_user(
          name: [name_prefix, api_user.fetch("name")].join,
          email: email,
        )
      end
    end

  private

    attr_reader :namespace, :name_prefix

    def find_or_create_api_user(name:, email:)
      return if ApiUser.exists?(email: email)

      password = SecureRandom.urlsafe_base64
      api_user = ApiUser.new(name: name, email: email,
                             password: password, password_confirmation: password)
      api_user.skip_confirmation!
      api_user.api_user = true
      api_user.save!
    end
  end
end
