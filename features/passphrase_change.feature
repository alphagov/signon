Feature: Password change
  Scenario: Successfully change the passphrase
    Given a signed-in user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I change the passphrase to "4 totally! dzzzifferent pass-phrase"
    Then I should see "Your passphrase was changed successfully."

  Scenario: Unsuccessfully change the passphrase due to a weak passphrase
    Given a signed-in user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I change the passphrase to "Zyzzogeton"
    Then I should see "not strong enough"

  Scenario: Unsuccessfully change the passphrase due to a too-short passphrase
    Given a signed-in user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I change the passphrase to "shore"
    Then I should see "too short"
