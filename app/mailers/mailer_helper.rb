module MailerHelper
  def email_from
    "#{app_name} <#{email_from_address}>"
  end

  def app_name
    I18n.t('mailer.app_name', instance_name: instance_name)
  end

  def email_from_address
    if instance_name.present?
      I18n.t('mailer.email_from_address.instance', instance_name: instance_name.parameterize)
    else
      I18n.t('mailer.email_from_address.no-instance')
    end
  end

  def instance_name
    Rails.application.config.instance_name
  end
end
