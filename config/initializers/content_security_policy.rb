GovukContentSecurityPolicy.configure do |policy|
  # Ensures the ability to use inline JavaScript without protections. This is
  # required for compatibility with govuk_admin_template which both uses script
  # tags without nonces and uses jQuery 1.x which requires unsafe-inline in
  # some browsers (Firefox is one)
  script_policy_with_unsafe_inline = (policy.script_src + ["'unsafe-inline'"]).uniq
  policy.script_src(*script_policy_with_unsafe_inline)
end

# Disable any configured nonce generators so that unsafe-inline directives
# can be used
Rails.application.config.content_security_policy_nonce_generator = nil
