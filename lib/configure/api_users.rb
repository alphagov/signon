module Configure
  class ApiUsers
    def initialize(namespace:, public_domain:, resource_name_prefix:)
      @namespace = namespace
      @name_prefix = resource_name_prefix
      @public_domain = public_domain
    end

    def configure!(api_users)
      api_users.each do |api_user|
        email = [namespace, "#{api_user.fetch('slug')}@#{public_domain}"].compact.join("-")
        find_or_create_api_user(
          name: [name_prefix, api_user.fetch("name")].join,
          email:,
        )
      end
    end

  private

    attr_reader :namespace, :name_prefix, :public_domain

    def find_or_create_api_user(name:, email:)
      return if ApiUser.exists?(email:)

      api_user = ApiUser.build(name:, email:)
      api_user.save!
    end
  end
end
