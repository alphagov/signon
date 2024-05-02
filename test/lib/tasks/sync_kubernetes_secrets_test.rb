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

      expect_secret_tokens_created_for_only_users(@client, api_users)

      Rake::Task["kubernetes:sync_token_secrets"].execute
    end

    should "create token secrets for non-suspended users only" do
      suspended_user = api_user_with_token("user1", token_count: 1)
      suspended_user.suspend("test")
      expected_user = api_user_with_token("user2", token_count: 2)

      expect_secret_tokens_created_for_only_users(@client, [expected_user])

      Rake::Task["kubernetes:sync_token_secrets"].execute
    end
  end

  context "#sync_app_secrets" do
    should "create app secrets for all non-retired apps" do
      app = create(:application)
      create(:application, retired: true)

      expect_secrets_created_for_only_apps(@client, [app])

      Rake::Task["kubernetes:sync_app_secrets"].execute
    end
  end

  def expect_secret_tokens_created_for_only_users(client, users)
    users.each do |user|
      user.authorisations.each do |authorisation|
        client.expects(:apply_secret).with(
          "signon-token-#{user.name}-#{authorisation.application.name}".parameterize,
          { bearer_token: authorisation.token },
        )
      end
    end
  end

  def expect_secrets_created_for_only_apps(client, apps)
    apps.each do |app|
      client.expects(:apply_secret).with(
        "signon-app-#{app.name}".parameterize,
        { oauth_id: app.uid, oauth_secret: app.secret },
      )
    end
  end
end
