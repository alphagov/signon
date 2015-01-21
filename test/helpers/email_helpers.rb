require 'capybara/email'

module EmailHelpers
  include Capybara::Email::DSL

  def last_email
    all_emails.last
  end
end
