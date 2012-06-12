Feature: Inviting users
  Scenario: Inviting a new user
    Given a signed-in admin user
    When I create an admin user called "Fred Bloggs" with email "fred@example.com"
    Then an admin user should be created with the email "fred@example.com"
    And an invitation email should be sent to "fred@example.com"
    
  Scenario: Accepting an invitation
    Given an invited user
    When I am at the invited user set password screen
    And I fill in the password
    Then I should see "You are now signed in"