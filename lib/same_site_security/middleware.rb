module SameSiteSecurity
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)
      status, headers, response = @app.call(env)
      if cookies = headers["Set-Cookie"]
        cookies = cookies.split("\n") unless cookies.is_a?(Array)

        headers["Set-Cookie"] = cookies.map { |cookie|
          cookie.to_s + "; SameSite=Lax"
        }.join("\n")
      end
      [status, headers, response]
    end
  end
end
