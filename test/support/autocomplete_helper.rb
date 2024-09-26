require "capybara/rails"

class AutocompleteHelper
  include Capybara::DSL

  def select_autocomplete_option(option_string)
    autocomplete_input_element = find(".autocomplete__input")
    autocomplete_input_element.fill_in with: option_string
    autocomplete_option = find(".autocomplete__option")
    autocomplete_option.click
  end
end
