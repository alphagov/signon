Feature: Changing email addresses
  Scenario: Admin changes a user's email
    Given a signed-in admin user
    And another user
    When I change their email to "new@email.com"
    Then a confirmation email should be sent to "new@email.com"

  Scenario: Confirming an email change
    Given a user with a pending email change
    When the confirm email link is clicked
    Then I should see "Confirm a change to your account email"
    When I fill in the passphrase
    And I submit
    Then I should see "Your account was successfully confirmed. You are now signed in."

  Scenario: Admin changes email of a user who hasn't accepted their invite yet
    Given a signed-in admin user
    And an invited user
    When I change their email to "new@email.com"
    And I sign-out
    Then an invitation email should be sent to "new@email.com"
    And the invitation email link is clicked
    And I fill in the password
    Then I should see "You are now signed in"

  Scenario: Admin realises that an email change was in error
    Given a signed-in admin user
    And a user with a pending email change
    When I cancel the email change
    And I sign-out
    When the confirm email link is clicked
    Then I should see "Confirmation token is invalid"