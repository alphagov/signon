class EventLog < ActiveRecord::Base
  ACCOUNT_LOCKED = "Account locked"
  ACCOUNT_SUSPENDED = "Account suspended"
  ACCOUNT_UNSUSPENDED = "Account unsuspended"
  MANUAL_ACCOUNT_UNLOCK = "Manual account unlock"
  PASSPHRASE_EXPIRED = "Passphrase expired"
  PASSPHRASE_RESET_REQUEST = "Passphrase reset request"
  SUCCESSFUL_PASSPHRASE_CHANGE = "Successful passphrase change"
  SUCCESSFUL_LOGIN = "Successful login"
  UNSUCCESSFUL_LOGIN = "Unsuccessful login"
  SUSPENDED_ACCOUNT_AUTHENTICATED_LOGIN = "Unsuccessful login attempt to a suspended account, with the correct username and password"
  UNSUCCESSFUL_PASSPHRASE_CHANGE = "Unsuccessful passphrase change"

  EVENTS_REQUIRING_INITIATOR = [ACCOUNT_SUSPENDED, ACCOUNT_UNSUSPENDED, MANUAL_ACCOUNT_UNLOCK]

  validates :uid, presence: true
  validates :event, presence: true
  validates_presence_of :initiator_id, if: Proc.new { |event_log| EVENTS_REQUIRING_INITIATOR.include? event_log.event }

  belongs_to :initiator, class_name: "User"

  def self.record_event(user, event, initiator = nil)
    attributes = { uid: user.uid, event: event }
    attributes.merge!(initiator_id: initiator.id) if initiator

    EventLog.create(attributes)
  end

  def self.for(user)
    EventLog.order('created_at DESC').where(uid: user.uid).limit(100)
  end

end
