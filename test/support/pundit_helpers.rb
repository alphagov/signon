module PunditHelpers
  def stub_policy(current_user, record, method_and_return_value)
    policy_class = Pundit::PolicyFinder.new(record).policy
    record = record.last if record.is_a?(Array)
    policy = stub_everything("policy", method_and_return_value).responds_like_instance_of(policy_class)
    policy_class.stubs(:new).with(current_user, record).returns(policy)
  end
end
