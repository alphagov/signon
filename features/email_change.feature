Feature: Changing email addresses
  Scenario: Admin changes email of a user who hasn't accepted their invite yet
    Given a signed-in admin user
    And an invited user
    When I change their email to "new@email.com"
    And I sign-out
    Then an invitation email should be sent to "new@email.com"
    And the invitation email link is clicked
    And I fill in my new passphrase
    Then I should see "You are now signed in"

  Scenario: Admin realises that an email change was in error
    Given a signed-in admin user
    And a user with a pending email change
    When I cancel their email change
    And I sign-out
    When the confirm email link is clicked
    Then I should see "Couldn't confirm email change. Please contact support to request a new confirmation email."

  Scenario: User changes their own email
    Given a signed-in user
    When I change my email to "new@email.com"
    Then a confirmation email should be sent to "new@email.com"

  Scenario: User realises that an email change was in error
    Given a signed-in user
    And I am a user with a pending email change
    When I cancel my email change
    When the confirm email link is clicked
    Then I should see "Couldn't confirm email change. Please contact support to request a new confirmation email."
