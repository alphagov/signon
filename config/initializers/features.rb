module Features
  CREATE_ORGANISATION_ADMIN = Rails.env.dev? || Rails.env.test?
end
