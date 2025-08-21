class FailureApp < Devise::FailureApp
protected

  def store_location!
    super unless attempted_path
      &.bytesize
      &.>(ActionDispatch::Cookies::MAX_COOKIE_SIZE / 2)
  end
end
