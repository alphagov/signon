require "test_helper"

class Kubernetes::ClientTest < ActiveSupport::TestCase
  context "#new" do
    should "initialise a client with defaults" do
      File.stubs(:exist?).with(Kubernetes::Client::CA_FILE)
        .returns(false).once

      Kubeclient::Client.stubs(:new).with(
        Kubernetes::Client::API_SERVER,
        Kubernetes::Client::API_VERSION,
        auth_options: { bearer_token_file: Kubernetes::Client::BEARER_TOKEN_FILE },
        ssl_options: {},
      ).once

      Kubernetes::Client.new
    end

    should "initialise a client with CA file if exists" do
      File.stubs(:exist?).with(Kubernetes::Client::CA_FILE)
        .returns(true).once

      Kubeclient::Client.stubs(:new).with(
        Kubernetes::Client::API_SERVER,
        Kubernetes::Client::API_VERSION,
        auth_options: { bearer_token_file: Kubernetes::Client::BEARER_TOKEN_FILE },
        ssl_options: { ca_file: Kubernetes::Client::CA_FILE },
      ).once

      Kubernetes::Client.new
    end
  end

  context "#namespace" do
    should "return the namespace stored filepath" do
      Kubeclient::Client.stubs(:new)

      File.stubs(:read).with(Kubernetes::Client::NAMESPACE_FILE)
        .returns("apps").once

      client = Kubernetes::Client.new

      assert_equal "apps", client.namespace
    end
  end

  context "#get_config_map" do
    should "call get config map from kubernetes API" do
      kubeclient = mock("kubeclient")
      config_map = mock("config_map")
      kubeclient.expects(:get_config_map).with("configmap_name", "apps").returns(config_map)

      Kubeclient::Client.stubs(:new).returns(kubeclient)

      client = Kubernetes::Client.new
      client.stubs(:namespace).returns("apps")

      assert_equal config_map, client.get_config_map("configmap_name")
    end
  end

  context "#apply_secret" do
    should "call apply secret from kubernetes API" do
      kubeclient = mock("kubeclient")
      Kubeclient::Client.stubs(:new).returns(kubeclient)
      config = {
        apiVersion: Kubernetes::Client::API_VERSION,
        kind: "Secret",
        metadata: {
          name: "name",
          namespace: "apps",
        },
        type: "Opaque",
        data: { "key" => "dmFsdWU=\n" },
      }
      resource = Kubeclient::Resource.new(config)
      Kubeclient::Resource.stubs(:new).with(config).returns(resource)
      kubeclient.expects(:apply_secret).with(resource, field_manager: "signon")

      client = Kubernetes::Client.new
      client.stubs(:namespace).returns("apps")

      client.apply_secret("name", { "key" => "value" })
    end
  end
end
