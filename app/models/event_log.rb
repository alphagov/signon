class EventLog < ActiveRecord::Base
  AUTOMATIC_ACCOUNT_UNLOCK = "Automatic account unlock"
  ACCOUNT_LOCKED = "Account locked"
  ACCOUNT_SUSPENDED = "Account suspended"
  ACCOUNT_UNSUSPENDED = "Account unsuspended"
  PASSPHRASE_EXPIRED = "Passphrase expired"
  PASSPHRASE_RESET_REQUEST = "Passphrase reset request"
  SUCCESSFUL_PASSPHRASE_CHANGE = "Successful passphrase change"
  SUCCESSFUL_LOGIN = "Successful login"
  UNSUCCESSFUL_LOGIN = "Unsuccessful login"
  UNSUCCESSFUL_PASSPHRASE_CHANGE = "Unsuccessful passphrase change"

  validates :uid, presence: true
  validates :event, presence: true

  def self.record_event(user, event)
    EventLog.create(uid: user.uid, event: event)
  end

  def self.for(user)
    EventLog.order('created_at DESC').where(uid: user.uid).limit(100)
  end
end
