module ApiUsersHelper
  def truncate_access_token(token)
    raw "#{token[0..7]}#{'&bull;' * 24}#{token[-8..-1]}"
  end
end
