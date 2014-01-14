require 'test_helper'
 
class AuthoriseApplicationTest < ActionDispatch::IntegrationTest
  setup do
    @app = create(:application, name: "MyApp")
    @user = create(:user)
  end

  should "confirm the authorisation for a signed-out user" do
    begin
      visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
    rescue ActionController::RoutingError, SocketError
    end

    assert_response_contains("You need to sign in")
    
    begin
      signin(@user)
    rescue ActionController::RoutingError, SocketError
    end
    assert_kind_of Doorkeeper::AccessGrant, Doorkeeper::AccessGrant.find_by_resource_owner_id(@user.id)
  end

  should "confirm the authorisation for a signed-in user" do
    visit "/"
    signin(@user)

    begin
      visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
    rescue ActionController::RoutingError, SocketError
    end

    assert_kind_of Doorkeeper::AccessGrant, Doorkeeper::AccessGrant.find_by_resource_owner_id(@user.id)
  end
end
