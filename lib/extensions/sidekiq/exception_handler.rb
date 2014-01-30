module Sidekiq
  module ExceptionHandler

    def handle_exception_with_restraint(ex, ctxHash={})
      max_retry_count = ctxHash['retry'] if ctxHash['retry'].is_a? Fixnum
      max_retry_count ||= ctxHash['class'].constantize.get_sidekiq_options['retry']
      return if ctxHash['retry_count'] < max_retry_count

      handle_exception_without_restraint(ex, ctxHash)
    end
    alias_method_chain :handle_exception, :restraint

  end
end
