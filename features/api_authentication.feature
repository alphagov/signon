Feature: API Authentication
  Scenario: A user with a valid access token
    Given a signed-in user
      And an OAuth application called "MyApp" with SupportedPermission of "write"
      And the user is authorized for "MyApp" with permission to "write"
    When I request user details with a valid bearer token
    Then I should receive a successful JSON response
      And I should get a list of the user's permissions for "MyApp"

  Scenario: Without an access token
    Given a signed-in user
      And an OAuth application called "MyApp" with SupportedPermission of "write"
      And the user is authorized for "MyApp" with permission to "write"
    When I request user details without a bearer token
    Then the response should indicate it needs authorization

  Scenario: With an invalid access token
    Given a signed-in user
      And an OAuth application called "MyApp" with SupportedPermission of "write"
      And the user is authorized for "MyApp" with permission to "write"
    When I request user details with an invalid bearer token
    Then the response should indicate it needs authorization

  Scenario: When access token has expired
    Given a signed-in user
      And an OAuth application called "MyApp" with SupportedPermission of "write"
      And the user is authorized for "MyApp" with permission to "write"
    When I request user details with an expired bearer token
    Then the response should indicate it needs authorization

  Scenario: When access token has been revoked
    Given a signed-in user
      And an OAuth application called "MyApp" with SupportedPermission of "write"
      And the user is authorized for "MyApp" with permission to "write"
    When I request user details with a revoked bearer token
    Then the response should indicate it needs authorization