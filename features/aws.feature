Feature: The AWS plugin on a project row
  Once the plugin is activated and installed, every site row carries the AWS menu, and the Plugins
  page lists the plugin with its four steps.

  Scenario: A site row offers the AWS menu, captioned with its link state
    Given I am on "/dev"
     Then the element ".act-menu-aws" should be displayed
      And I should see "AWS"
      And the element ".act-menu-aws + .act-status" should be displayed

  Scenario: An unlinked project's menu opens and says how to link it
    Given I am on "/dev"
      And I click on the element ".project-row .act-menu-aws button"
     Then ".uk-dropdown.uk-open" should be visible
      And I should see "Not linked to AWS"

  Scenario: The plugin is listed on the Plugins page
    Given I am on "/settings/plugins"
     Then I should see "AWS"
      And I should see "@webship.co/workspace-aws"
