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
      end

      should "return value of GOVUK_ENVIRONMENT_NAME if it is set" do
        ClimateControl.modify(GOVUK_ENVIRONMENT_NAME: "govuk-environment-name") do
          assert_equal "govuk-environment-name", GovukEnvironment.name
        end
      end

      should "fail fast if GOVUK_ENVIRONMENT_NAME is not set" do
        ClimateControl.modify(GOVUK_ENVIRONMENT_NAME: nil) do
          assert_raises(KeyError) { GovukEnvironment.name }
        end
      end
    end
  end

  context ".production?" do
    context "when name is 'production'" do
      setup do
        GovukEnvironment.stubs(:name).returns("production")
      end

      should "return truthy" do
        assert GovukEnvironment.production?
      end
    end

    context "when name is not 'production'" do
      setup do
        GovukEnvironment.stubs(:name).returns("not-production")
      end

      should "return falsey" do
        assert_not GovukEnvironment.production?
      end
    end
  end
end
