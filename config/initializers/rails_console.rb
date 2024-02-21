Rails.application.console do
  Current.user = ApiUser.for_rails_console
end
