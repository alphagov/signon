module CurrentHelpers
  def with_current(user: nil, user_ip: nil)
    original_user = Current.user
    original_ip_address = Current.user_ip
    begin
      Current.user = user
      Current.user_ip = user_ip
      yield
    ensure
      Current.user = original_user
      Current.user_ip = original_ip_address
    end
  end
end
