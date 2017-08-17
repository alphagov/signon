class BulkGrantPermissionSetJob < ActiveJob::Base
  def perform(id, options = {})
    BulkGrantPermissionSet.find(id).perform(options)
  end
end
