class RejectNonGovernmentalEmailAddressesValidator < ActiveModel::EachValidator
  NON_GOVERNMENTAL_EMAIL_DOMAIN_KEYWORDS = %w[
    aol btinternet gmail hotmail outlook yahoo
  ].freeze

  MESSAGE = "not accepted. Please enter a workplace email to continue.".freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    domain_part = value.split("@").last

    return if domain_part.blank?

    if keyword_matchers.any? { |keyword| keyword.match?(domain_part) }
      record.errors.add(attribute, options[:message] || MESSAGE)
    end
  end

private

  def keyword_matchers
    NON_GOVERNMENTAL_EMAIL_DOMAIN_KEYWORDS.map { |keyword| /\b#{keyword}\b/ }
  end
end
