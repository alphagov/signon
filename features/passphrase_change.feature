Feature: Password change
  Scenario: Successfully change the passphrase
    Given a signed-in user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I change the passphrase from "some v3ry s3cure passphrase" to "4 totally! dzzzifferent pass-phrase"
    Then I should see "Your passphrase was changed successfully."
    And my passphrase should be "4 totally! dzzzifferent pass-phrase"

  Scenario: Unsuccessfully change the passphrase due to not providing existing passphrase
    Given a signed-in user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I enter a new passphrase of "some ev3n mor3 s3cure passphrase"
    Then I should see "Current password can't be blank"
    And my passphrase should still be "some v3ry s3cure passphrase"

  Scenario: Unsuccessfully change the passphrase due to providing incorrect existing passphrase
    Given a signed-in user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I change the passphrase from "some not v3ry s3cure passphrase" to "Zyzzogeton"
    Then I should see "Current password is invalid"
    And my passphrase should still be "some v3ry s3cure passphrase"

  Scenario: Unsuccessfully change the passphrase due to a weak passphrase
    Given a signed-in user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I change the passphrase from "some v3ry s3cure passphrase" to "Zyzzogeton"
    Then I should see "not strong enough"
    And my passphrase should still be "some v3ry s3cure passphrase"

  Scenario: Unsuccessfully change the passphrase due to a too-short passphrase
    Given a signed-in user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I change the passphrase from "some v3ry s3cure passphrase" to "shore"
    Then I should see "too short"
    And my passphrase should still be "some v3ry s3cure passphrase"

  Scenario: Unsuccessfully change the passphrase due to bad confirmationpassphrase
    Given a signed-in user exists with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    When I try to change the passphrase from "some v3ry s3cure passphrase" to "shore" and "not shore"
    Then I should see "doesn't match confirmation"
    And my passphrase should still be "some v3ry s3cure passphrase"