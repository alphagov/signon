require 'capybara/email'

module EmailHelpers
  include Capybara::Email::DSL

  def last_email
    all_emails.last
  end

  def last_email_for(email_address)
    all_emails.reverse.find { |email| email.to.include? email_address }
  end
end
