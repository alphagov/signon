Feature: User suspension
  Scenario: Suspended accounts can't sign in
    Given a user exists with email "email@example.com" and passphrase "some passphrase with various $ymb0l$"
    And "email@example.com" is a suspended account
    When I try to sign in with email "email@example.com" and passphrase "some passphrase with various $ymb0l$"
    Then I should see "Invalid email or passphrase"
