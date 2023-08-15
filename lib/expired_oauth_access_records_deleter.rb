class ExpiredOauthAccessRecordsDeleter
  def initialize(klass:)
    @klass = klass
    @total_deleted = 0
  end

  attr_reader :total_deleted

  def delete_expired
    ids = [nil]

    until ids.empty?
      ids = @klass
        .where("expires_in is not null AND DATE_ADD(created_at, INTERVAL expires_in second) < ?", Time.zone.now)
        .limit(1000)
        .pluck(:id)

      @total_deleted += ids.size

      @klass.where(id: ids).delete_all
    end
  end
end
