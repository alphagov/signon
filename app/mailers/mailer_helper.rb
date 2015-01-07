module MailerHelper
  def email_from
    "#{app_name} <#{email_from_address}>"
  end

  def app_name
    if instance_name.present?
      "GOV.UK Signon #{instance_name}"
    else
      "GOV.UK Signon"
    end
  end

  def email_from_address
    if instance_name.present?
      "noreply-signon-#{instance_name.parameterize}@digital.cabinet-office.gov.uk"
    else
      "noreply-signon@digital.cabinet-office.gov.uk"
    end
  end

  def instance_name
    Rails.application.config.instance_name
  end
end
