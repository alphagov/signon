Feature: Authorise Application
  Scenario: A signed-out user granting access to a registered OAuth application
    Given a signed-out user
    And an OAuth application called "MyApp"
    When I visit the OAuth authorisation request endpoint for "MyApp"
    Then I should see "You need to sign in"
    When I sign in, ignoring routing errors
    Then there should be an authorisation code for the user

  Scenario: A signed-in user granting access to a registered OAuth application
    Given a signed-in user
    And an OAuth application called "MyApp"
    When I visit the OAuth authorisation request endpoint for "MyApp"
    Then there should be an authorisation code for the user