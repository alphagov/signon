Feature: Password change
  Scenario: Successfully change the passphrase
    Given a signed-in user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I change the passphrase to "a totally different passphrase"
    Then I should see "Passphrase successfully changed"

  Scenario: Unsuccessfully change the passphrase due to a weak passphrase
    Given a signed-in user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I change the passphrase to "password"
    Then I should see "not strong enough"
