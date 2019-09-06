class LogEntry
  attr_reader :id, :description

  def initialize(id:, description:, require_uid: false, require_initiator: false, require_application: false)
    @id = id
    @description = description
    @require_uid = require_uid
    @require_initiator = require_initiator
    @require_application = require_application
  end

  def require_uid?
    @require_uid
  end

  def require_initiator?
    @require_initiator
  end

  def require_application?
    @require_application
  end
end
