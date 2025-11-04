require "test_helper"

class GlobalPrometheusCollectorTest < ActiveSupport::TestCase
  def setup
    @collector = Collectors::GlobalPrometheusCollector.new
    @api_user = create(:api_user_with_tokens, token_count: 4)
  end

  context "#metrics" do
    should "list all non-revoked token expiry timestamps for non-retired aps" do
      @api_user.authorisations[2].revoke
      @api_user.authorisations[3].application.update!(retired: true)

      metrics = @collector.metrics

      assert_equal metrics.first.data, {
        {
          api_user: @api_user.email,
          application: @api_user.authorisations.first.application.name.parameterize,
        } => @api_user.authorisations.first.expires_at.to_i,
        {
          api_user: @api_user.email,
          application: @api_user.authorisations.second.application.name.parameterize,
        } => @api_user.authorisations.second.expires_at.to_i,
      }
    end
  end
end
