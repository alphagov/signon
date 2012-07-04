Feature: Granting Permissions
  Scenario: Giving a user the "access" permission
    Given a signed-in admin user
    And another user
    And an OAuth application called "MyApp"
    When I give the user access to "MyApp"
    Then a permission should be created for "MyApp" with permissions of "signin"

# Permission::PERMISSIONS currently only has "signin"
#  Scenario: Granting a user permissions
#    Given a signed-in admin user
#    And another user
#    And an OAuth application called "MyApp"
#    When I add "some other permission" permission to "MyApp"
#    Then a permission should be created for "MyApp" with permissions of "some other permission"
