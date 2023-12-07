module CurrentHelpers
  def with_current(user: nil, user_ip: nil)
    original_user = Current.user
    original_user_ip = Current.user_ip
    begin
      Current.user = user
      Current.user_ip = user_ip
      yield
    ensure
      Current.user = original_user
      Current.user_ip = original_user_ip
    end
  end
end
