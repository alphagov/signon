class SessionsController < Devise::SessionsController

  # FIXME: remove this once we're at Devise 3.2.0 or higher. Please.
  if Devise::VERSION == "2.2.5"
    # Devise::SessionsController defines three filters, all using
    # `prepend_before_filter`. The one we want (that skips Devise's timeout
    # logic) is the last one defined, so it should be the first one in the
    # callback chain
    timeout_callback = _process_action_callbacks.first { |callback|
      callback.klass == Devise::SessionsController
    }

    # Do a bunch of checks to make sure this is the callback that skips the
    # timeout. In Devise 2.2.5, it's the only one defined as an anonymous Proc,
    # and it's the only one without an :only or :except condition (which
    # translate to :if and :unless respectively once they hit activesupport).
    callback_checks = [
      timeout_callback.present?,
      timeout_callback.kind == :before,
      timeout_callback.raw_filter.is_a?(Proc),
      timeout_callback.per_key == {:if=>[], :unless=>[]},
    ]
    unless callback_checks.all?
      raise "Something is wrong with the timeout callback: aborting"
    end

    # The `filter` method usually refers to the method on the controller that
    # the filter invokes; when it's defined as an anonymous method, the name
    # gets generated on the fly, making it harder to get hold of it.
    timeout_callback_name = timeout_callback.filter
    skip_before_filter timeout_callback_name, except: [:create, :destroy]
  else
    raise "This hack only applies to Devise 2.2.5: aborting"
  end

  def destroy
    ReauthEnforcer.perform_on(current_user) if current_user
    super
  end

  def create
    log_event
    super
  end

  private

  def log_event
    if current_user.present?
      EventLog.record_event(current_user, EventLog::SUCCESSFUL_LOGIN)
    else
      # Call to_s to flatten out any unexpected params (eg a hash).
      user = User.find_by_email(params[:user][:email].to_s)
      EventLog.record_event(user, EventLog::UNSUCCESSFUL_LOGIN) if user
    end
  end
end
