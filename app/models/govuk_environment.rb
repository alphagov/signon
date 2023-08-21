class GovukEnvironment
  def self.name
    if Rails.env.development? || Rails.env.test?
      "development"
    else
      ENV["GOVUK_ENVIRONMENT_NAME"]
    end
  end

  def self.production?
    name == "production"
  end
end
