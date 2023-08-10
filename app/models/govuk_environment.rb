class GovukEnvironment
  def self.name
    if Rails.env.development? || Rails.env.test?
      "development"
    else
      ENV["INSTANCE_NAME"]
    end
  end

  def self.production?
    name.blank?
  end
end
