namespace :access_tokens do
  desc "Renew expiring access tokens for internal applications"
  task renew_expiring_internal_tokens: :environment do
    expiring_tokens = Doorkeeper::AccessToken.expires_before(1.month.from_now)

    expiring_tokens.each do |token|
      user = User.find_by(id: token.resource_owner_id)
      next unless user&.email&.match(/@(alphagov\.co\.uk|publishing\.service\.gov\.uk)$/)

      newer_tokens = Doorkeeper::AccessToken.where(
        application_id: token.application_id,
        resource_owner_id: token.resource_owner_id,
      ).expires_after(token.expires_at)

      next if newer_tokens.any?

      authorisation = user.authorisations.build(
        application_id: token.application_id,
        expires_in: ApiUser::DEFAULT_TOKEN_LIFE,
      )

      if authorisation.save
        user.grant_application_signin_permission(authorisation.application)
        EventLog.record_event(user, EventLog::ACCESS_TOKEN_AUTO_GENERATED, application: authorisation.application)
      end
    end
  end
end
