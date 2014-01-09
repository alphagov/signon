Feature: Changing email addresses
  Scenario: User realises that an email change was in error
    Given a signed-in user
    And I am a user with a pending email change
    When I cancel my email change
    When the confirm email link is clicked
    Then I should see "Couldn't confirm email change. Please contact support to request a new confirmation email."
