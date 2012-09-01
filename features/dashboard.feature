Feature: User dashboard
  Scenario: A user who has no authorised applications
    Given a signed-in user
    When I go to the homepage
    Then I should see "Your Applications"
      And I should see "You aren't yet assigned to any applications"

  Scenario: A user who has authorised applications
    Given a signed-in user
      And an OAuth application called "MyApp" with SupportedPermission of "write"
      And the user is authorized for "MyApp" with permission to "write"
    When I go to the homepage
    Then I should see "Your Applications"
      And I should see a link and description for "MyApp"