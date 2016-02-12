# this is required to catch errors thrown from calls to I18n directly - primarily mailers

if Rails.env.test?
  module I18n
    class AlwaysRaiseExceptionHandler < ExceptionHandler
      def call(exception, locale, key, options)
        if exception.is_a?(MissingTranslation)
          raise exception.to_exception
        else
          super
        end
      end
    end
  end

  I18n.exception_handler = I18n::AlwaysRaiseExceptionHandler.new
end
