Feature: Passphrase reset
  Scenario: Not showing too much information after failed request
    Given no user exists with email "email@example.com"
    When I request a new passphrase for "email@example.com"
    Then I should not see "Email not found"

  Scenario: Successfully change the passphrase
    Given a user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I change the passphrase to "a totally different passphrase" from "some v3ry s3cure passphrase"
    Then I should see "Passphrase successfully changed"

  Scenario: Unsuccessfully change the passphrase
    Given a user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I change the passphrase to "password" from "some v3ry s3cure passphrase"
    Then I should see "not strong enough"
