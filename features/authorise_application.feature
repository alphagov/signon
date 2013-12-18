Feature: Authorise Application
  Background:
    Given an OAuth application called "MyApp"

  Scenario: A signed-out user granting access to a registered OAuth application
    Given a signed-out user
    When I visit the OAuth authorisation request endpoint for "MyApp"
    Then I should see "You need to sign in"
    When I sign in, ignoring routing errors
    Then there should be an authorisation code for the user

  Scenario: A signed-in user granting access to a registered OAuth application
    Given a signed-in user
    When I visit the OAuth authorisation request endpoint for "MyApp"
    Then there should be an authorisation code for the user