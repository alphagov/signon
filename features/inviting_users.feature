Feature: Inviting users
  Scenario: Inviting a new user
    Given a signed-in admin user
    When I create a user called "Fred Bloggs" with email "fred@example.com"
    Then a user should be created with the email "fred@example.com"
    And an invitation email should be sent to "fred@example.com"

  Scenario: Inviting a new admin
    Given a signed-in superadmin user
    When I create an admin called "Fred Bloggs" with email "fred@example.com"
    Then a user should be created with the email "fred@example.com"
    And an invitation email should be sent to "fred@example.com"
    
  Scenario: Accepting an invitation
    Given an invited user
    When the invitation email link is clicked
    And I fill in my new passphrase
    Then I should see "You are now signed in"
