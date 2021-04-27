require "test_helper"

class ConfigureApiUsersTest < ActiveSupport::TestCase
  test "creates required api users" do
    Configure::ApiUsers.new(
      namespace: nil, resource_name_prefix: nil,
    ).configure!(api_users)

    api_users.each do |api_user|
      assert ApiUser.exists?(
        email: "#{api_user.fetch('slug')}@digital.cabinet-office.gov.uk",
        name: api_user.fetch("name"),
      )
    end
  end

  test "namespaces api user name and emails" do
    namespace = "test"
    prefix = "[Test!] "
    Configure::ApiUsers.new(
      namespace: namespace, resource_name_prefix: prefix,
    ).configure!(api_users)

    api_users.each do |api_user|
      assert ApiUser.exists?(
        email: "#{namespace}-#{api_user.fetch('slug')}@digital.cabinet-office.gov.uk",
        name: prefix + api_user.fetch("name"),
      )
    end
  end

  test "#configure! is idempotent and non-destructive" do
    email = "#{api_users.first.fetch('slug')}@digital.cabinet-office.gov.uk"
    name = "Pre-existing api_user"
    create(:api_user, email: email, name: name)

    Configure::ApiUsers.new(
      namespace: nil,
      resource_name_prefix: nil,
    ).configure!(api_users)

    assert ApiUser.exists?(email: email, name: name)
    assert_not ApiUser.exists?(email: email, name: api_users.first.fetch("name"))

    api_users[1..].each do |api_user|
      assert ApiUser.exists?(
        email: "#{api_user.fetch('slug')}@digital.cabinet-office.gov.uk",
        name: api_user.fetch("name"),
      )
    end
  end

  def api_users
    @api_users ||= [
      {
        "name" => "Business Support Finder App",
        "slug" => "businesssupportfinder",
      },
      {
        "name" => "Calculators App",
        "slug" => "calculators",
      },
    ]
  end
end
