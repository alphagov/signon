require "test_helper"

class KubernetesTaskTest < ActiveSupport::TestCase
  setup do
    Signon::Application.load_tasks if Rake::Task.tasks.empty?

    @api_users = [
      api_user_with_token("user1", token_count: 2),
      api_user_with_token("user2", token_count: 1),
    ]

    @client = mock("kubernetes-client")
    Kubernetes::Client.stubs(:new).returns(@client)
  end

  context "#sync_token_secrets" do
    should "create all token secrets for multiple users" do
      stub_user_config_map(@client, @api_users.map(&:email))
      expect_secret_tokens_created_for_users(@client, @api_users)

      Rake::Task["kubernetes:sync_token_secrets"].execute({
        config_map_name: "config_map_name",
        environment_name: "test",
      })
    end

    should "create all token secrets for only users specified" do
      specified_user = @api_users[0]

      stub_user_config_map(@client, [specified_user.email])
      expect_secret_tokens_created_for_users(@client, [specified_user])

      Rake::Task["kubernetes:sync_token_secrets"].execute({
        config_map_name: "config_map_name",
        environment_name: "test",
      })
    end

    should "raise an exception about missing user, but not skip other existing users" do
      emails = [@api_users[0].email, "do-not-exist@example.com", @api_users[1].email]

      stub_user_config_map(@client, emails)
      expect_secret_tokens_created_for_users(@client, @api_users)

      err = assert_raises StandardError do
        Rake::Task["kubernetes:sync_token_secrets"].execute({
          config_map_name: "config_map_name",
          environment_name: "test",
        })
      end

      assert_match(/do-not-exist@example.com/, err.message)
    end

    should "raise an exception if environment doesn't exist" do
      stub_user_config_map(@client, ["test@example.com"])

      err = assert_raises StandardError do
        Rake::Task["kubernetes:sync_token_secrets"].execute({
          config_map_name: "config_map_name",
          environment_name: "doesnotexist",
        })
      end

      assert_match(/doesnotexist/, err.message)
    end
  end

  def expect_secret_tokens_created_for_users(client, users)
    users.each do |user|
      user.authorisations.each do |authorisation|
        client.expects(:apply_secret).with(
          "signon-token-#{user.name}-#{authorisation.application.name}".parameterize,
          { bearer_token: authorisation.token },
        ).once
      end
    end
  end

  def stub_user_config_map(client, emails)
    email_list = emails.map { |e| "\"#{e}\"" }.join(",")

    client.stubs(:get_config_map).with("config_map_name").returns(
      Kubeclient::Resource.new({
        data: { "test" => "{\"api_user_emails\": [#{email_list}]}" },
      }),
    ).once
  end
end
