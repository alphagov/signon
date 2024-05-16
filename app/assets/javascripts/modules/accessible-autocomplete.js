//= require accessible-autocomplete/dist/accessible-autocomplete.min.js

window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {}

;(function (Modules) {
  'use strict'

  function AccessibleAutocomplete ($module) {
    this.$module = $module
  }

  AccessibleAutocomplete.prototype.init = function () {
    const selectElement = this.$module.querySelector('[data-module="accessible-autocomplete"] select')
    const configOptions = {
      autoselect: true,
      defaultValue: '',
      preserveNullOptions: true,
      selectElement: selectElement,
      showAllValues: true
    }

    new window.accessibleAutocomplete.enhanceSelectElement(configOptions) // eslint-disable-line no-new, new-cap

    const autocompleteElement = selectElement.parentNode.querySelector('.autocomplete__input')
    resetSelectWhenDesynced(selectElement, autocompleteElement)
    enableClearButton(selectElement, autocompleteElement)
  }

  Modules.AccessibleAutocomplete = AccessibleAutocomplete
})(window.GOVUK.Modules)

function resetSelectWhenDesynced (selectElement, autocompleteElement) {
  // if the autocomplete element's value no longer matches the selected option
  // in the select element, reset the select element - in particular, this
  // avoids submitting the last selected value after clearing the input
  // @see https://github.com/alphagov/accessible-autocomplete/issues/205

  autocompleteElement.addEventListener('keyup', function () {
    const optionSelectedInSelectElement = selectElement.querySelector('option:checked')

    if (autocompleteElement.value !== optionSelectedInSelectElement.innerText) {
      selectElement.value = ''
    }
  })
}

function enableClearButton (selectElement, autocompleteElement) {
  const clearButton = document.querySelector('.js-autocomplete__clear-button')

  if (clearButton) {
    clearButton.addEventListener('click', function () {
      resetSelectAndAutocomplete(selectElement, autocompleteElement, clearButton)
    })

    clearButton.addEventListener('keydown', function (event) {
      if (event.key === ' ' || event.key === 'Enter') {
        resetSelectAndAutocomplete(selectElement, autocompleteElement, clearButton)
      }
    })

    clearButton.classList.add('js-autocomplete__clear-button--enabled')
  }
}

function resetSelectAndAutocomplete (selectElement, autocompleteElement, clearButton) {
  autocompleteElement.value = ''
  selectElement.value = ''

  autocompleteElement.click()
  autocompleteElement.focus()
  autocompleteElement.blur()

  clearButton.focus()
}
