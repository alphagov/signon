Feature: Passphrase reset
  Scenario: Not showing too much information after failed request
    Given no user exists with email "email@example.com"
    When I request a new passphrase for "email@example.com"
    Then I should not see "Email not found"

  Scenario: Successfully request a passphrase reset
    Given a user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I request a new passphrase for "email@example.com"
    Then I should see "You will receive an email with instructions about how to reset your password in a few minutes."
