class EventLog < ActiveRecord::Base
  deprecated_columns :event

  LOCKED_DURATION = "#{Devise.unlock_in / 1.hour} #{'hour'.pluralize(Devise.unlock_in / 1.hour)}"

  EVENTS = [
    ACCOUNT_LOCKED                            = LogEntry.new(id: 1, description: "Passphrase verification failed too many times, account locked for #{LOCKED_DURATION}"),
    ACCOUNT_SUSPENDED                         = LogEntry.new(id: 2, description: "Account suspended", require_initiator: true),
    ACCOUNT_UNSUSPENDED                       = LogEntry.new(id: 3, description: "Account unsuspended", require_initiator: true),
    ACCOUNT_AUTOSUSPENDED                     = LogEntry.new(id: 4, description: "Account auto-suspended"),
    MANUAL_ACCOUNT_UNLOCK                     = LogEntry.new(id: 5, description: "Manual account unlock", require_initiator: true),
    PASSPHRASE_EXPIRED                        = LogEntry.new(id: 6, description: "Passphrase expired"),
    PASSPHRASE_RESET_REQUEST                  = LogEntry.new(id: 7, description: "Passphrase reset request"),
    PASSPHRASE_RESET_LOADED                   = LogEntry.new(id: 8, description: "Passphrase reset page loaded"),
    PASSPHRASE_RESET_FAILURE                  = LogEntry.new(id: 9, description: "Passphrase reset attempt failure"),
    SUCCESSFUL_PASSPHRASE_CHANGE              = LogEntry.new(id: 10, description: "Successful passphrase change"),
    SUCCESSFUL_LOGIN                          = LogEntry.new(id: 11, description: "Successful login"),
    UNSUCCESSFUL_LOGIN                        = LogEntry.new(id: 12, description: "Unsuccessful login"),
    SUSPENDED_ACCOUNT_AUTHENTICATED_LOGIN     = LogEntry.new(id: 13, description: "Unsuccessful login attempt to a suspended account, with the correct username and password"),
    UNSUCCESSFUL_PASSPHRASE_CHANGE            = LogEntry.new(id: 14, description: "Unsuccessful passphrase change"),
    EMAIL_CHANGED                             = LogEntry.new(id: 15, description: "Email changed", require_initiator: true),
    EMAIL_CHANGE_INITIATED                    = LogEntry.new(id: 16, description: "Email change initiated"),
    EMAIL_CHANGE_CONFIRMED                    = LogEntry.new(id: 17, description: "Email change confirmed"),
    TWO_STEP_ENABLED                          = LogEntry.new(id: 18, description: "2-step verification enabled"),
    TWO_STEP_RESET                            = LogEntry.new(id: 19, description: "2-step verification reset"),
    TWO_STEP_ENABLE_FAILED                    = LogEntry.new(id: 20, description: "2-step verification setup failed"),
    TWO_STEP_VERIFIED                         = LogEntry.new(id: 21, description: "2-step verification successful"),
    TWO_STEP_VERIFICATION_FAILED              = LogEntry.new(id: 22, description: "2-step verification failed"),
    TWO_STEP_LOCKED                           = LogEntry.new(id: 23, description: "2-step verification failed too many times, account locked for #{LOCKED_DURATION}"),
    TWO_STEP_CHANGED                          = LogEntry.new(id: 24, description: "2-step verification phone changed"),
    TWO_STEP_CHANGE_FAILED                    = LogEntry.new(id: 25, description: "2-step verification phone change failed"),
    TWO_STEP_PROMPT_DEFERRED                  = LogEntry.new(id: 26, description: "2-step prompt deferred"),
    API_USER_CREATED                          = LogEntry.new(id: 27, description: "Account created", require_initiator: true),
    ACCESS_TOKEN_REGENERATED                  = LogEntry.new(id: 28, description: "Access token re-generated", require_application: true),
    ACCESS_TOKEN_GENERATED                    = LogEntry.new(id: 29, description: "Access token generated", require_application: true, require_initiator: true),
    ACCESS_TOKEN_REVOKED                      = LogEntry.new(id: 30, description: "Access token revoked", require_application: true, require_initiator: true),
    PASSPHRASE_RESET_LOADED_BUT_TOKEN_EXPIRED = LogEntry.new(id: 31, description: "Passphrase reset page loaded but the token has expired"),
    SUCCESSFUL_PASSPHRASE_RESET               = LogEntry.new(id: 32, description: "Passphrase reset successfully"),
    ROLE_CHANGED                              = LogEntry.new(id: 33, description: "Role changed", require_initiator: true),
    ACCOUNT_UPDATED                           = LogEntry.new(id: 34, description: "Account updated", require_initiator: true),
    PERMISSIONS_ADDED                         = LogEntry.new(id: 35, description: "Permissions added", require_initiator: true),
    PERMISSIONS_REMOVED                       = LogEntry.new(id: 36, description: "Permissions removed", require_initiator: true),
  ]

  EVENTS_REQUIRING_INITIATOR   = EVENTS.select(&:require_initiator?)
  EVENTS_REQUIRING_APPLICATION = EVENTS.select(&:require_application?)

  VALID_OPTIONS = [:initiator, :application, :application_id, :trailing_message]

  validates :uid, presence: true
  validates_presence_of :event_id
  validate :validate_event_mappable
  validates_presence_of :initiator_id,   if: Proc.new { |event_log| EVENTS_REQUIRING_INITIATOR.include? event_log.entry }
  validates_presence_of :application_id, if: Proc.new { |event_log| EVENTS_REQUIRING_APPLICATION.include? event_log.entry }

  belongs_to :initiator, class_name: "User"
  belongs_to :application, class_name: "Doorkeeper::Application"

  def event
    entry.description
  end

  def entry
    EVENTS.detect { |event| event.id == event_id }
  end

  def self.record_event(user, event, options = {})
    attributes = {
      uid: user.uid,
      event_id: event.id
    }.merge!(options.slice(*VALID_OPTIONS))

    EventLog.create!(attributes)
  end

  def self.record_email_change(user, email_was, email_is, initiator = user)
    event = (user == initiator) ? EMAIL_CHANGE_INITIATED : EMAIL_CHANGED
    record_event(user, event, initiator: initiator, trailing_message: "from #{email_was} to #{email_is}")
  end

  def self.record_role_change(user, previous_role, new_role, initiator)
    record_event(user, ROLE_CHANGED, initiator: initiator, trailing_message: "from #{previous_role} to #{new_role}")
  end

  def self.for(user)
    EventLog.order('created_at DESC').where(uid: user.uid)
  end

private
  def validate_event_mappable
    unless entry
      errors.add(:event_id, "must have a corresponding `LogEntry` for #{event_id}")
    end
  end
end
