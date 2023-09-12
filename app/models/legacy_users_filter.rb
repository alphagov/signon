class LegacyUsersFilter
  PARAM_KEYS = %i[status two_step_status role permission organisation].freeze
  LEGACY_TWO_STEP_STATUS_VS_TWO_STEP_STATUS = {
    "true" => User::TWO_STEP_STATUS_ENABLED,
    "false" => User::TWO_STEP_STATUS_NOT_SET_UP,
    "exempt" => User::TWO_STEP_STATUS_EXEMPTED,
  }.freeze

  def initialize(options = {})
    @options = options
  end

  def redirect?
    !@options.slice(*PARAM_KEYS).empty?
  end

  def options
    @options.except(*PARAM_KEYS).tap do |o|
      o[:statuses] = [@options[:status]] if @options[:status].present?
      o[:two_step_statuses] = [two_step_status_from(@options[:two_step_status])] if @options[:two_step_status].present?
      o[:roles] = [@options[:role]] if @options[:role].present?
      o[:organisations] = [@options[:organisation]] if @options[:organisation].present?
      o[:permissions] = [@options[:permission]] if @options[:permission].present?
    end
  end

private

  def two_step_status_from(legacy_two_step_status)
    LEGACY_TWO_STEP_STATUS_VS_TWO_STEP_STATUS[legacy_two_step_status]
  end
end
