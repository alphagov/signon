module AutocompleteHelpers
  def assert_select_with_autocomplete(
    autocomplete_input_element:,
    select_element:,
    option_text:,
    option_value:,
    unique_partial_string:
  )
    assert_equal "", autocomplete_input_element.value
    assert_equal "", select_element.value

    # when I type a few characters from the option that are unique to that option
    autocomplete_input_element.fill_in with: unique_partial_string
    autocomplete_option = find(".autocomplete__option")

    # the autcomplete value reflects what I typed, a matching option appears, but the select element remains empty
    assert_equal unique_partial_string, autocomplete_input_element.value
    assert_equal option_text, autocomplete_option.text
    assert_equal "", select_element.value

    # when I click on the matching option
    autocomplete_option.click

    # the autocomplete and select elements reflect my selection
    assert_equal option_text, autocomplete_input_element.value
    assert_equal option_value, select_element.value
  end
end
