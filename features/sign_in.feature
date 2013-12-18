Feature: Signing in
  Background:
    Given a user exists with email "email@example.com" and passphrase "some passphrase with various $ymb0l$"

  Scenario: Successful sign in
    When I try to sign in with email "email@example.com" and passphrase "some passphrase with various $ymb0l$"
    Then I should see "Signed in successfully."

  Scenario: Unsuccessful sign in
    When I try to sign in with email "email@example.com" and passphrase "some incorrect passphrase $ymb0l$"
    Then I should see "Invalid email or passphrase"

  Scenario: My proxy sets the Client-IP HTTP Header
    Given my requests include a Client-IP HTTP Header
    When I try to sign in with email "email@example.com" and passphrase "some passphrase with various $ymb0l$"
    Then I should see "Signed in successfully."
