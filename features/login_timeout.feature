Feature: Restrictions around signin
  Scenario: Locking accounts after many failed signin attempts
    Given a user exists with email "email@example.com" and passphrase "some passphrase with various $ymb0l$"
    When I try to sign in 7 times with email "email@example.com" and passphrase "not really"
#    Then I should see "Too many failed login attempts. Please wait an hour and try again or contact an admin."
    Then I should see "Your account is locked."
