Feature: Looking at all the events today

  Scenario: I search for today's events
    Given I am on the "events" page
    When I click "Today"
    Then I should see "film"