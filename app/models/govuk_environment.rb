class GovukEnvironment
  def self.name
    if Rails.env.development? || Rails.env.test?
      "development"
    else
      ENV["INSTANCE_NAME"]
    end
  end
end
