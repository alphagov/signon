module RootHelper
  def should_list_app?(permission, application)
    permission.permissions.include?("signin") || application.name == "Support"
  end
end
