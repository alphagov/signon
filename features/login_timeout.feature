Feature: Restrictions around signin
#  Disabled for now so we can upgrade Devise - it's behaviour has been changed in this situation
#  https://www.pivotaltracker.com/story/show/43324959
#  https://github.com/plataformatec/devise/commit/00a01c2bc494ce17269036fadd62ff14a76833ca
#  Scenario: Locking accounts after many failed signin attempts
#    Given a user exists with email "email@example.com" and passphrase "some passphrase with various $ymb0l$"
#    When I try to sign in 7 times with email "email@example.com" and passphrase "not really"
#    Then I should see "Your account is locked."

  Scenario: Admin users can unlock accounts
    Given a user exists with email "email@example.com" and passphrase "some passphrase with various $ymb0l$"
      And they have been locked out
      And a signed-in admin user
    When I go to the list of users
    Then I should see a button to unlock account

    When I press the unlock button
    Then "email@example.com" should be unlocked