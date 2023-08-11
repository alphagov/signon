class ExpiredOauthAccessRecordsDeleter
  CLASSES = {
    access_grant: Doorkeeper::AccessGrant,
    access_token: Doorkeeper::AccessToken,
  }.freeze
  EVENTS = {
    access_grant: EventLog::ACCESS_GRANTS_DELETED,
    access_token: EventLog::ACCESS_TOKENS_DELETED,
  }.freeze

  HAS_EXPIRED = "expires_in is not null AND DATE_ADD(created_at, INTERVAL expires_in second) < ?".freeze

  def initialize(record_type:)
    @record_class = CLASSES.fetch(record_type)
    @event = EVENTS.fetch(record_type)
    @total_deleted = 0
  end

  attr_reader :record_class, :total_deleted

  def delete_expired
    @record_class.where(HAS_EXPIRED, Time.zone.now).in_batches do |relation|
      records_by_user_id = relation.includes(:application).group_by(&:resource_owner_id)
      all_users = User.where(id: records_by_user_id.keys)

      all_users.each do |user|
        application_names = records_by_user_id[user.id].map { |record| record.application.name }

        EventLog.record_event(
          user,
          @event,
          trailing_message: "for #{application_names.to_sentence}",
        )
      end

      @total_deleted += relation.delete_all
    end
  end
end
