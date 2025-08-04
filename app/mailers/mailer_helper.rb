module MailerHelper
  def email_from
    "#{app_name} <#{email_from_address}>"
  end

  def app_name
    I18n.t("mailer.app_name.instance", instance_name: GovukEnvironment.current)
  end

  def email_from_address
    if GovukEnvironment.current == "production"
      I18n.t("mailer.email_from_address.no_instance")
    else
      I18n.t("mailer.email_from_address.instance", instance_name: GovukEnvironment.current.parameterize)
    end
  end
end
