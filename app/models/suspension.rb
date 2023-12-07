class Suspension
  include ActiveModel::Validations
  validates :reason_for_suspension, presence: true, if: :suspend

  attr_reader :suspend, :reason_for_suspension, :user, :initiator

  def initialize(suspend: nil, reason_for_suspension: nil, user: nil, initiator: nil)
    @suspend = suspend
    @reason_for_suspension = reason_for_suspension
    @user = user
    @initiator = initiator
  end

  def save
    return false unless valid?

    if suspend
      user.suspend(reason_for_suspension)
    else
      user.unsuspend
    end

    EventLog.record_event(user, action, initiator:, ip_address: true)
    PermissionUpdater.perform_on(user)
    ReauthEnforcer.perform_on(user)
  end
  alias_method :save!, :save

  def suspended?
    suspend
  end

private

  def action
    if suspend
      EventLog::ACCOUNT_SUSPENDED
    else
      EventLog::ACCOUNT_UNSUSPENDED
    end
  end
end
