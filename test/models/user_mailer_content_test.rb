require "test_helper"
class UserMailerContentTest < ActionMailer::TestCase
  # Use sparingly to apply exemptions to the below due to awkward setups
  # that work but do not fit the below patterns
  exemptions = [
    "app/views/user_mailer/suspension_reminder.html.erb",
    "app/views/user_mailer/suspension_notification.html.erb",
  ]

  context "considering all email content" do
    should "have no malformed links in html content files" do
      found_errors = []
      file_list = Dir.glob("app/views/user_mailer/*.html.erb").to_a - exemptions

      file_list.each do |file_path|
        file = File.open file_path
        content = file.read
        # Number of link_to calls made total
        base_size = content.scan(/link_to/).size

        # e.g. "<%= link_to "support form", t('support.url') %>"
        found_examples = content.scan(/<%= link_to [^']*, t\('[^']*.url'\) %>/)

        # e.g "<%= link_to t('department.name'), t('department.url') %>"
        found_examples += content.scan(/<%= link_to t\('[^']*'\), t\('[^']*.url'\) %>/)

        # Sometimes we have this specific pattern, we should check for it too
        found_examples += content.scan(/<%= link_to 'sign in', new_user_session_url\(protocol\: 'https'\) %>/)

        if found_examples.size != base_size
          found_errors.push(file_path)
        end
      end

      assert(found_errors.empty?, "The following files have malformed link_to calls to be investigated: #{found_errors}")
    end
  end
end
