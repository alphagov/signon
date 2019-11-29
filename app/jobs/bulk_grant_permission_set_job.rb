class BulkGrantPermissionSetJob < ApplicationJob
  def perform(id, options = {})
    BulkGrantPermissionSet.find(id).perform(options)
  end
end
