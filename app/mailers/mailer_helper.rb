module MailerHelper
  def email_from
    "#{app_name} <#{email_from_address}>"
  end

  def app_name
    if GovukEnvironment.production?
      I18n.t("mailer.app_name.no_instance")
    else
      I18n.t("mailer.app_name.instance", instance_name: GovukEnvironment.name)
    end
  end

  def email_from_address
    if GovukEnvironment.production?
      I18n.t("mailer.email_from_address.no_instance")
    else
      I18n.t("mailer.email_from_address.instance", instance_name: GovukEnvironment.name.parameterize)
    end
  end
end
