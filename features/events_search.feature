Feature: Searching events in the area

  Scenario: I search for "goteborg" events
    Given I am on the "events" page
    When I fill in "query" with "goteborg"
    And I click "Get Events"
    Then I should see "HIVE"
    And I should see "onsdag"
    And I should not see "Super awesome shit"