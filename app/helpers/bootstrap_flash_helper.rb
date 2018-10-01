module BootstrapFlashHelper
  def bootstrap_flash_message_keys
    %i[success info warning danger error notice alert].select { |k| flash[k].present? }
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
end
