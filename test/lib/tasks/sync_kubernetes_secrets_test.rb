require "test_helper"

class KubernetesTaskTest < ActiveSupport::TestCase
  setup do
    Signon::Application.load_tasks if Rake::Task.tasks.empty?

    @client = mock("kubernetes-client")
    Kubernetes::Client.stubs(:new).returns(@client)
  end

  context "#sync_token_secrets" do
    should "create all token secrets for multiple users" do
      api_users = [
        api_user_with_token("user1", token_count: 2),
        api_user_with_token("user2", token_count: 1),
      ]

      stub_config_map(@client, [], api_users.map(&:email))
      expect_secret_tokens_created_for_only_users(@client, api_users)

      Rake::Task["kubernetes:sync_token_secrets"].execute({
        config_map_name: "config_map_name",
      })
    end

    should "create all token secrets for only users specified" do
      api_users = [
        api_user_with_token("user1", token_count: 2),
        api_user_with_token("user2", token_count: 1),
      ]

      specified_user = api_users[0]

      stub_config_map(@client, [], [specified_user.email])
      expect_secret_tokens_created_for_only_users(@client, [specified_user])

      Rake::Task["kubernetes:sync_token_secrets"].execute({
        config_map_name: "config_map_name",
      })
    end

    should "raise an exception about missing user, but not skip other existing users" do
      api_users = [
        api_user_with_token("user1", token_count: 2),
        api_user_with_token("user2", token_count: 1),
      ]

      emails = [api_users[0].email, "do-not-exist@example.com", api_users[1].email]

      stub_config_map(@client, [], emails)
      expect_secret_tokens_created_for_only_users(@client, api_users)

      err = assert_raises StandardError do
        Rake::Task["kubernetes:sync_token_secrets"].execute({
          config_map_name: "config_map_name",
        })
      end

      assert_match(/do-not-exist@example.com/, err.message)
    end
  end

  context "#sync_app_secrets" do
    should "create all app secrets for only specified apps" do
      app = create(:application)
      create(:application)

      stub_config_map(@client, [app.name], [])
      expect_secrets_created_for_only_apps(@client, [app])

      Rake::Task["kubernetes:sync_app_secrets"].execute({
        config_map_name: "config_map_name",
      })
    end

    should "raise an exception about missing app, but not skip other existing apps" do
      apps = [create(:application), create(:application)]
      names = [apps[0].name, "Do Not Exist", apps[1].name]

      stub_config_map(@client, names, [])
      expect_secrets_created_for_only_apps(@client, apps)

      err = assert_raises StandardError do
        Rake::Task["kubernetes:sync_app_secrets"].execute({
          config_map_name: "config_map_name",
        })
      end

      assert_match(/Do Not Exist/, err.message)
    end

    should "raise an exception about retired app" do
      app = create(:application, retired: true)

      stub_config_map(@client, [app.name], [])
      expect_secrets_created_for_only_apps(@client, [])

      err = assert_raises StandardError do
        Rake::Task["kubernetes:sync_app_secrets"].execute({
          config_map_name: "config_map_name",
        })
      end

      assert_match(/#{app.name}/, err.message)
    end
  end

  def expect_secret_tokens_created_for_only_users(client, users)
    users.each do |user|
      user.authorisations.each do |authorisation|
        client.expects(:apply_secret).with(
          "signon-token-#{user.name}-#{authorisation.application.name}".parameterize,
          { bearer_token: authorisation.token },
        ).once
      end
    end
  end

  def expect_secrets_created_for_only_apps(client, apps)
    apps.each do |app|
      client.expects(:apply_secret).with(
        "signon-app-#{app.name}".parameterize,
        { oauth_id: app.uid, oauth_secret: app.secret },
      ).once
    end
  end

  def stub_config_map(client, app_names, emails)
    email_list = emails.map { |e| %("#{e}") }.join(",")
    names_list = app_names.map { |n| %("#{n}") }.join(",")

    client.stubs(:get_config_map).with("config_map_name").returns(
      Kubeclient::Resource.new({
        data: { "app_names" => "[#{names_list}]",
                "api_user_emails" => "[#{email_list}]" },
      }),
    ).once
  end
end
