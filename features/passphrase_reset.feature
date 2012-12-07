Feature: Passphrase reset
  Scenario: Not showing too much information after failed request
    Given no user exists with email "email@example.com"
    When I request a new passphrase for "email@example.com"
    Then I should not see "Email not found"
    Then I should see "If your e-mail exists on our database, you will receive a passphrase recovery link on your e-mail"

  Scenario: Not showing too much information after an SES blacklist error occurs
    Given a user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    And SES will raise a blacklist error
    When I request a new passphrase for "email@example.com"
    Then I should not see "Email not found"
    Then I should see "If your e-mail exists on our database, you will receive a passphrase recovery link on your e-mail"

  Scenario: Successfully request a passphrase reset
    Given a user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I request a new passphrase for "email@example.com"
    Then I should see "If your e-mail exists on our database, you will receive a passphrase recovery link on your e-mail"

  Scenario: Successfully completing a passphrase reset
    Given a user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I request a new passphrase for "email@example.com"
      And I complete the passphrase reset form setting my passphrase to "some ev3n m0r3 s3cure passphrase"
    Then my passphrase should be "some ev3n m0r3 s3cure passphrase"
      And I should see "Your passphrase was changed successfully"
