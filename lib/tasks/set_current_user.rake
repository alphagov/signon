desc "Sets Current.user"
task set_current_user: :environment do
  Current.user = ApiUser.for_rake_task
end
