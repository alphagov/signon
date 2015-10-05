module BootstrapFlashHelper
  def bootstrap_flash_message_keys
    [:success, :info, :warning, :danger, :error, :notice, :alert].select { |k| flash[k].present? }
  end

  def bootstrap_flash_class(flash_key)
    case flash_key
    when :notice
      "success"
    when :error, :alert
      "danger"
    else
      flash_key
    end
  end

  def flash_text_without_email_addresses(message)
    text_message = strip_tags(message)

    # redact email addresses so they aren't passed to GA
    text_message.gsub(/[\S]+@[\S]+/, '[email]')
  end
end
