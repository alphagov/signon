module Api
  class UserPresenter
    def self.present_many(users)
      users.map { |user| present(user) }
    end

    def self.present(user)
      new(user).present
    end

    def present
      {
        uid: @user.uid,
        name: @user.name,
        email: @user.email,
        organisation: organisation,
      }
    end

  private

    def initialize(user)
      @user = user
    end

    def organisation
      organisation = @user.organisation

      if organisation
        {
          content_id: organisation.content_id,
          name: organisation.name,
          slug: organisation.slug,
        }
      end
    end
  end
end
