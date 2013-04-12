Feature: Inviting a batch of users
  Scenario: Inviting a batch of new users
    Given a signed-in admin user
    When I upload "users.csv"
    Then I should see "Creating a batch of users"
    And I should see "Success! 1 users processed"
    And a user should be created with the email "fred@example.com"
    And an invitation email should be sent to "fred@example.com"
