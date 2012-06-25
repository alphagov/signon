Feature: Granting Permissions
  Scenario: Adding a permission
    Given a signed-in admin user
    And another user
    And an OAuth application called "MyApp"
    When I add "signin" permission to "MyApp"
    Then a permission should be created for "MyApp" with permissions of "signin"
