class EventLog < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  ACCOUNT_LOCKED = "Account locked"
  ACCOUNT_SUSPENDED = "Account suspended"
  ACCOUNT_UNSUSPENDED = "Account unsuspended"
  ACCOUNT_AUTOSUSPENDED = "Account auto-suspended"
  MANUAL_ACCOUNT_UNLOCK = "Manual account unlock"
  PASSPHRASE_EXPIRED = "Passphrase expired"
  PASSPHRASE_RESET_REQUEST = "Passphrase reset request"
  SUCCESSFUL_PASSPHRASE_CHANGE = "Successful passphrase change"
  SUCCESSFUL_LOGIN = "Successful login"
  UNSUCCESSFUL_LOGIN = "Unsuccessful login"
  SUSPENDED_ACCOUNT_AUTHENTICATED_LOGIN = "Unsuccessful login attempt to a suspended account, with the correct username and password"
  UNSUCCESSFUL_PASSPHRASE_CHANGE = "Unsuccessful passphrase change"
  EMAIL_CHANGED = "Email changed"
  EMAIL_CHANGE_INITIATED = "Email change initiated"
  EMAIL_CHANGE_CONFIRMED = "Email change confirmed"

  # API users
  API_USER_CREATED = "Account created"
  ACCESS_TOKEN_REGENERATED = "Access token re-generated"
  ACCESS_TOKEN_GENERATED = "Access token generated"
  ACCESS_TOKEN_REVOKED = "Access token revoked"

  EVENTS_REQUIRING_INITIATOR = [ACCOUNT_SUSPENDED,
                                ACCOUNT_UNSUSPENDED,
                                MANUAL_ACCOUNT_UNLOCK,
                                API_USER_CREATED,
                                ACCESS_TOKEN_GENERATED,
                                ACCESS_TOKEN_REVOKED,
                                EMAIL_CHANGED]

  EVENTS_REQUIRING_APPLICATION_ID = [ACCESS_TOKEN_REGENERATED, ACCESS_TOKEN_GENERATED, ACCESS_TOKEN_REVOKED]
  VALID_OPTIONS = [:initiator, :application, :trailing_message]

  validates :uid, presence: true
  validates :event, presence: true
  validates_presence_of :initiator_id, if: Proc.new { |event_log| EVENTS_REQUIRING_INITIATOR.include? event_log.event }
  validates_presence_of :application_id, if: Proc.new { |event_log| EVENTS_REQUIRING_APPLICATION_ID.include? event_log.event }

  belongs_to :initiator, class_name: "User"
  belongs_to :application, class_name: "Doorkeeper::Application"

  def self.record_event(user, event, options={})
    attributes = { uid: user.uid, event: event }.merge!(options.slice(*VALID_OPTIONS))
    EventLog.create(attributes)
  end

  def self.record_email_change(user, email_was, email_is, initiator=user)
    event = (user == initiator) ? EMAIL_CHANGE_INITIATED : EMAIL_CHANGED
    record_event(user, event, initiator: initiator, trailing_message: "from #{email_was} to #{email_is}")
  end

  def self.for(user)
    EventLog.order('created_at DESC').where(uid: user.uid)
  end
end
