require "ipaddr"

class EventLog < ApplicationRecord
  deprecated_columns :event

  LOCKED_DURATION = "#{Devise.unlock_in / 1.hour} #{'hour'.pluralize(Devise.unlock_in / 1.hour)}".freeze

  EVENTS = [
    ACCOUNT_LOCKED = LogEntry.new(id: 1, description: "Password verification failed too many times, account locked for #{LOCKED_DURATION}", require_uid: true),
    ACCOUNT_SUSPENDED = LogEntry.new(id: 2, description: "Account suspended", require_uid: true, require_initiator: true),
    ACCOUNT_UNSUSPENDED = LogEntry.new(id: 3, description: "Account unsuspended", require_uid: true, require_initiator: true),
    ACCOUNT_AUTOSUSPENDED = LogEntry.new(id: 4, description: "Account auto-suspended", require_uid: true),
    MANUAL_ACCOUNT_UNLOCK = LogEntry.new(id: 5, description: "Manual account unlock", require_uid: true, require_initiator: true),
    PASSWORD_RESET_REQUEST = LogEntry.new(id: 7, description: "Password reset request", require_uid: true),
    PASSWORD_RESET_LOADED = LogEntry.new(id: 8, description: "Password reset page loaded", require_uid: true),
    PASSWORD_RESET_FAILURE = LogEntry.new(id: 9, description: "Password reset attempt failure", require_uid: true),
    SUCCESSFUL_PASSWORD_CHANGE = LogEntry.new(id: 10, description: "Successful password change", require_uid: true),
    SUCCESSFUL_LOGIN = LogEntry.new(id: 11, description: "Successful login", require_uid: true),
    UNSUCCESSFUL_LOGIN = LogEntry.new(id: 12, description: "Unsuccessful login", require_uid: true),
    SUSPENDED_ACCOUNT_AUTHENTICATED_LOGIN = LogEntry.new(id: 13, description: "Unsuccessful login attempt to a suspended account, with the correct username and password", require_uid: true),
    UNSUCCESSFUL_PASSWORD_CHANGE = LogEntry.new(id: 14, description: "Unsuccessful password change", require_uid: true),
    EMAIL_CHANGED = LogEntry.new(id: 15, description: "Email changed", require_uid: true, require_initiator: true),
    EMAIL_CHANGE_INITIATED = LogEntry.new(id: 16, description: "Email change initiated", require_uid: true),
    EMAIL_CHANGE_CONFIRMED = LogEntry.new(id: 17, description: "Email change confirmed", require_uid: true),
    TWO_STEP_ENABLED = LogEntry.new(id: 18, description: "2-step verification enabled", require_uid: true),
    TWO_STEP_RESET = LogEntry.new(id: 19, description: "2-step verification reset", require_uid: true),
    TWO_STEP_ENABLE_FAILED = LogEntry.new(id: 20, description: "2-step verification setup failed", require_uid: true),
    TWO_STEP_VERIFIED = LogEntry.new(id: 21, description: "2-step verification successful", require_uid: true),
    TWO_STEP_VERIFICATION_FAILED = LogEntry.new(id: 22, description: "2-step verification failed", require_uid: true),
    TWO_STEP_LOCKED = LogEntry.new(id: 23, description: "2-step verification failed too many times, account locked for #{LOCKED_DURATION}", require_uid: true),
    TWO_STEP_CHANGED = LogEntry.new(id: 24, description: "2-step verification phone changed", require_uid: true),
    TWO_STEP_CHANGE_FAILED = LogEntry.new(id: 25, description: "2-step verification phone change failed", require_uid: true),
    TWO_STEP_PROMPT_DEFERRED = LogEntry.new(id: 26, description: "2-step prompt deferred", require_uid: true),
    API_USER_CREATED = LogEntry.new(id: 27, description: "Account created", require_uid: true, require_initiator: true),
    ACCESS_TOKEN_REGENERATED = LogEntry.new(id: 28, description: "Access token re-generated", require_uid: true, require_application: true),
    ACCESS_TOKEN_GENERATED = LogEntry.new(id: 29, description: "Access token generated", require_uid: true, require_application: true, require_initiator: true),
    ACCESS_TOKEN_REVOKED = LogEntry.new(id: 30, description: "Access token revoked", require_uid: true, require_application: true, require_initiator: true),
    PASSWORD_RESET_LOADED_BUT_TOKEN_EXPIRED = LogEntry.new(id: 31, description: "Password reset page loaded but the token has expired", require_uid: true),
    SUCCESSFUL_PASSWORD_RESET = LogEntry.new(id: 32, description: "Password reset successfully", require_uid: true),
    ROLE_CHANGED = LogEntry.new(id: 33, description: "Role changed", require_uid: true, require_initiator: true),
    ACCOUNT_UPDATED = LogEntry.new(id: 34, description: "Account updated", require_uid: true, require_initiator: true),
    PERMISSIONS_ADDED = LogEntry.new(id: 35, description: "Permissions added", require_uid: true, require_initiator: true),
    PERMISSIONS_REMOVED = LogEntry.new(id: 36, description: "Permissions removed", require_uid: true, require_initiator: true),
    ACCOUNT_INVITED = LogEntry.new(id: 37, description: "Account was invited", require_uid: true, require_initiator: true),
    NO_SUCH_ACCOUNT_LOGIN = LogEntry.new(id: 38, description: "Attempted login to nonexistent account"),

    # We no longer expire passwords, but we keep this event for history purposes
    PASSWORD_EXPIRED = LogEntry.new(id: 6, description: "Password expired"),
  ].freeze

  EVENTS_REQUIRING_UID = EVENTS.select(&:require_uid?)
  EVENTS_REQUIRING_INITIATOR = EVENTS.select(&:require_initiator?)
  EVENTS_REQUIRING_APPLICATION = EVENTS.select(&:require_application?)

  VALID_OPTIONS = %i[initiator application application_id trailing_message ip_address user_agent_id user_agent_string user_email_string].freeze

  validates :uid, presence: { if: proc { |event_log| EVENTS_REQUIRING_UID.include? event_log.entry } }
  validates :event_id, presence: true
  validate :validate_event_mappable
  validates :initiator_id,   presence: { if: proc { |event_log| EVENTS_REQUIRING_INITIATOR.include? event_log.entry } }
  validates :application_id, presence: { if: proc { |event_log| EVENTS_REQUIRING_APPLICATION.include? event_log.entry } }

  belongs_to :initiator, class_name: "User"
  belongs_to :application, class_name: "Doorkeeper::Application"
  belongs_to :user_agent

  def user_agent_as_string
    user_agent&.user_agent_string || user_agent_string
  end

  def event
    entry.description
  end

  def entry
    EVENTS.detect { |event| event.id == event_id }
  end

  def ip_address_string
    self.class.convert_integer_to_ip_address(ip_address)
  end

  def send_to_splunk(*)
    return unless ENV["SPLUNK_EVENT_LOG_ENDPOINT_URL"] && ENV["SPLUNK_EVENT_LOG_ENDPOINT_HEC_TOKEN"]

    event = {
      timestamp: created_at.utc,
      app: application&.name,
      object_id: id,
      user: initiator&.name || user_email_string,
      user_uid: uid,
      src_ip: (ip_address_string if ip_address.present?),
      action: self.event,
      result: trailing_message,
      http_user_agent: user_agent_as_string,
    }

    conn = Faraday.new(ENV["SPLUNK_EVENT_LOG_ENDPOINT_URL"])
    conn.post do |request|
      request.headers["Content-Type"] = "application/json"
      request.headers["Authorization"] = "Splunk #{ENV['SPLUNK_EVENT_LOG_ENDPOINT_HEC_TOKEN']}"
      request.body = { event: event }.to_json
    end
  end

  def self.record_event(user, event, options = {})
    if options[:ip_address]
      options[:ip_address] = convert_ip_address_to_integer(options[:ip_address])
    end
    attributes = {
      uid: user&.uid,
      event_id: event.id,
    }.merge!(options.slice(*VALID_OPTIONS))

    event_log_entry = EventLog.create!(attributes)

    SplunkLogStreamingJob.perform_later(event_log_entry.id)

    event_log_entry
  end

  def self.record_email_change(user, email_was, email_is, initiator = user)
    event = user == initiator ? EMAIL_CHANGE_INITIATED : EMAIL_CHANGED
    record_event(user, event, initiator: initiator, trailing_message: "from #{email_was} to #{email_is}")
  end

  def self.record_role_change(user, previous_role, new_role, initiator)
    record_event(user, ROLE_CHANGED, initiator: initiator, trailing_message: "from #{previous_role} to #{new_role}")
  end

  def self.record_account_invitation(user, initiator)
    record_event(user, ACCOUNT_INVITED, initiator: initiator)
  end

  def self.for(user)
    EventLog.order("created_at DESC").where(uid: user.uid)
  end

  def self.convert_ip_address_to_integer(ip_address_string)
    IPAddr.new(ip_address_string).to_i
  end

  def self.convert_integer_to_ip_address(integer)
    if integer.to_s.length == 38
      # IPv6 address
      IPAddr.new(integer, Socket::AF_INET6).to_s
    else
      # IPv4 address
      IPAddr.new(integer, Socket::AF_INET).to_s
    end
  end

private

  def validate_event_mappable
    unless entry
      errors.add(:event_id, "must have a corresponding `LogEntry` for #{event_id}")
    end
  end
end
