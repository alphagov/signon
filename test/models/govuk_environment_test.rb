require "test_helper"

class GovukEnvironmentTest < ActionMailer::TestCase
  context ".name" do
    context "when in Rails development environment" do
      setup do
        Rails.env.stubs(:development?).returns(true)
        Rails.env.stubs(:test?).returns(false)
      end

      should "return 'development'" do
        assert_equal "development", GovukEnvironment.name
      end
    end

    context "when in Rails test environment" do
      setup do
        Rails.env.stubs(:development?).returns(false)
        Rails.env.stubs(:test?).returns(true)
      end

      should "return 'development'" do
        assert_equal "development", GovukEnvironment.name
      end
    end

    context "when not in Rails development or test environment" do
      setup do
        Rails.env.stubs(:development?).returns(false)
        Rails.env.stubs(:test?).returns(false)
        ENV.stubs(:[]).with("INSTANCE_NAME").returns("instance-name")
      end

      should "return value of INSTANCE_NAME env var" do
        assert_equal "instance-name", GovukEnvironment.name
      end
    end
  end
end
