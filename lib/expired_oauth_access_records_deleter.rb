class ExpiredOauthAccessRecordsDeleter
  HAS_EXPIRED = "expires_in is not null AND DATE_ADD(created_at, INTERVAL expires_in second) < ?".freeze

  def initialize(klass:)
    @klass = klass
    @total_deleted = 0
  end

  attr_reader :total_deleted

  def delete_expired
    @klass.where(HAS_EXPIRED, Time.zone.now).in_batches do |relation|
      @total_deleted += relation.delete_all
    end
  end
end
