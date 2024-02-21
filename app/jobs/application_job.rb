class ApplicationJob < ActiveJob::Base
  before_perform do
    Current.user = ApiUser.for_background_job
  end
end
