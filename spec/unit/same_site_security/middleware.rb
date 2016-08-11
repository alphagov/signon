require 'rails_helper'

describe SameSiteSecurity::Middleware do
  headers = {'Content-Type' => 'text/plain', 'Set-Cookie' => '_signonotron2_session=abcd'}
  let(:app) { Proc.new { [200, headers, ['OK']]} }
  subject { SameSiteSecurity::Middleware.new(app) }

  context "when called with a GET request" do
    let(:request) { Rack::MockRequest.new(subject) }

    it "sets cookies attributes properly" do
      env = Rack::MockRequest.env_for("/a-protected-url")
      status, headers = subject.call(env)

      cookies = headers['Set-Cookie']
      expect(cookies).to include('_signonotron2_session=abcd')
      expect(cookies).to include('SameSite=Lax')
    end
  end
end
