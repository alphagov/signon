Feature: User suspension
  Scenario: Suspended accounts can't sign in
    Given a user exists with email "email@example.com" and passphrase "some passphrase with various $ymb0l$"
    And "email@example.com" is a suspended account
    When I try to sign in with email "email@example.com" and passphrase "some passphrase with various $ymb0l$"
    Then I should see "account has been temporarily suspended"

  Scenario: Suspended accounts display reasoning
    Given a user exists with email "email@example.com" and passphrase "some passphrase with various $ymb0l$"
    And "email@example.com" is a suspended account because of "gross misconduct"
    And a signed-in admin user

    When I go to the edit page for "email@example.com"
    Then I should see that they were suspended for "gross misconduct"