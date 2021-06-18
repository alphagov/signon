Rack::Attack.throttle("limit 'POST /users/password' attempts per IP", limit: 20, period: 1.hour) do |request|
  if request.path == "/users/password" && request.post?
    request.env["action_dispatch.remote_ip"].to_s
  end
end

Rack::Attack.throttled_response = lambda do |_request|
  [429, { "Content-Type" => "text/plain" }, ["Too many requests."]]
end
