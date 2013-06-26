Feature: Passphrase expiry
  Scenario: Signing in 91 days after last changing my passphrase
    Given I am a user with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
      And I last changed my passphrase 91 days ago
    When I sign in
    Then I should see "Your passphrase has expired. Please choose a new passphrase"

  Scenario: Successfully changing passphrase
    Given I am being prompted for a new passphrase
    When I fill in the form with existing passphrase "some v3ry s3cure passphrase" and new passphrase "some 3v3n more s3cure passphrase"
    Then I should see "Your new passphrase is saved"
      And I should be on the dashboard

  Scenario: Returning to the exact path I wanted after changing passphrase
    Given I am a user with email "email@example.com" and passphrase "some v3ry s3cure passphrase"
    And I last changed my passphrase 91 days ago
    And I visit "/user/edit?arbitrary=1"
    When I sign in
    And I fill in the form with existing passphrase "some v3ry s3cure passphrase" and new passphrase "some 3v3n more s3cure passphrase"
    Then I should see "Your new passphrase is saved"
    And I should be on "/user/edit?arbitrary=1"

  Scenario: Making a mistake when choosing a new passphrase
    Given I am being prompted for a new passphrase
    When I make a mistake entering my existing passphrase
    Then I should continue to be prompted for a new passphrase

  Scenario: Navigating away before choosing a new passphrase
    Given I am being prompted for a new passphrase
    When I go to the dashboard
    Then I should continue to be prompted for a new passphrase
