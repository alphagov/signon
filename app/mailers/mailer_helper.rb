module MailerHelper
  def email_from
    "#{app_name} <#{email_from_address}>"
  end

  def app_name
    I18n.t("mailer.app_name", instance_name: GovukEnvironment.name)
  end

  def email_from_address
    if GovukEnvironment.name.present?
      I18n.t("mailer.email_from_address.instance", instance_name: GovukEnvironment.name.parameterize)
    else
      I18n.t("mailer.email_from_address.no-instance")
    end
  end
end
