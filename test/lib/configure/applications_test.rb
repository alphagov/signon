require "test_helper"

class ConfigureApplicationsTest < ActiveSupport::TestCase
  domain = "test.gov.example.org"
  name = "Cat herder"
  subdomain_name = "cats"
  description = "Herds cats"
  redirect_path = "/auth/gds/callback"
  permissions = %w[signin cat_herder]
  cats_app = {
    "name" => name,
    "description" => description,
    "permissions" => permissions,
    "redirect_path" => redirect_path,
    "subdomain_name" => subdomain_name,
  }

  test "creates required apps" do
    Configure::Applications.new(
      public_domain: domain, resource_name_prefix: nil,
    ).configure!([cats_app])

    created = Doorkeeper::Application.find_by(name: name)

    assert_equal created.name, name
    assert_equal created.redirect_uri, "https://#{subdomain_name}.#{domain}#{redirect_path}"
    assert_equal created.description, description
    assert_equal created.home_uri, "https://#{subdomain_name}.#{domain}"
  end

  test "creates associated permissions" do
    Configure::Applications.new(
      public_domain: domain, resource_name_prefix: nil,
    ).configure!([cats_app])

    created = Doorkeeper::Application.find_by(name: name)

    created_permissions = created.supported_permissions.pluck(:name)
    permissions.each do |permission|
      assert_contains created_permissions, permission
    end
  end

  test "namespaces api user name and emails" do
    prefix = "[Test!] "
    Configure::Applications.new(
      public_domain: domain, resource_name_prefix: prefix,
    ).configure!([cats_app])

    created = Doorkeeper::Application.find_by(name: prefix + name)

    assert_equal created.redirect_uri, "https://#{subdomain_name}.#{domain}#{redirect_path}"
    assert_equal created.redirect_uri, "https://#{subdomain_name}.#{domain}#{redirect_path}"
    assert_equal created.description, description
    assert_equal created.home_uri, "https://#{subdomain_name}.#{domain}"
  end

  test "#configure! is idempotent and non-destructive" do
    create(:application, name: name)

    Configure::Applications.new(
      public_domain: domain,
      resource_name_prefix: "[just testing] ",
    ).configure!([cats_app])

    application = Doorkeeper::Application.find_by(name: name)
    assert_not_equal application.description, description
    assert_not_includes application.home_uri, domain
  end
end
