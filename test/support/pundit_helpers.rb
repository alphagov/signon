module PunditHelpers
  def stub_policy(current_user, record, method_and_return_value)
    policy_class = Pundit::PolicyFinder.new(record).policy
    record = record.last if record.is_a?(Array)
    policy = stub_everything("policy", method_and_return_value).responds_like_instance_of(policy_class)
    policy_class.stubs(:new).with(current_user, record).returns(policy)
  end

  def stub_policy_for_navigation_links(current_user)
    stub_policy(current_user, User, index?: true)
    stub_policy(current_user, ApiUser, index?: true)
    stub_policy(current_user, Doorkeeper::Application, index?: true)
    stub_policy(current_user, Organisation, index?: true)
  end
end
