describe('GOVUK.Modules.AccessibleAutocomplete', function () {
  let component, module, autocompleteInput, selectInput

  beforeEach(async function () {
    component = document.createElement('div')
    component.setAttribute('data-module', 'accessible-autocomplete')
    component.innerHTML = `
      <label class="govuk-label govuk-label--m" for="new_permission_id">Add a permission</label>

      <div id="hint-1234" class="gem-c-hint govuk-hint">
        Search for the permission you want to add.

        <select name="application[new_permission_id]" id="new_permission_id" class="govuk-select" aria-describedby="hint-1234">
          <option value=""></option>
          <option value="1">permission-1</option>
          <option value="2">permission-2</option>
          <option value="3">permission-3</option>
          <option value="4">permission-4</option>
          <option value="5">permission-5</option>
          <option value="6">permission-6</option>
          <option value="7">permission-7</option>
          <option value="8">permission-8</option>
          <option value="9">permission-9</option>
        </select>
      </div>
    `
    module = new GOVUK.Modules.AccessibleAutocomplete(component)
    module.init()

    autocompleteInput = component.querySelector('.autocomplete__input')
    selectInput = component.querySelector('select')

    autocompleteInput.value = 'per'
    await wait()

    const firstAutocompleteListItem = component.querySelector('#new_permission_id__option--0')
    firstAutocompleteListItem.click()
    expect(autocompleteInput.value).toBe('permission-1')
    expect(selectInput.value).toBe('1')
  })

  it("resets the value of the select element when it no longer matches what's shown in the autocomplete input", async function () {
    autocompleteInput.value = 'permission-'
    autocompleteInput.dispatchEvent(new KeyboardEvent('keyup'))
    await wait()

    expect(selectInput.value).toBe('')
  })

  it('clears the value of the select and autocomplete elements when clicking the clear button', async function () {
    const clearButton = component.querySelector('.autocomplete__clear-button')
    clearButton.click()
    await wait()

    expect(selectInput.value).toBe('')
  })

  it('clears the value of the select and autocomplete elements when hitting space on the clear button', async function () {
    const clearButton = component.querySelector('.autocomplete__clear-button')
    clearButton.dispatchEvent(new KeyboardEvent('keydown', { key: ' ' }))
    await wait()

    expect(selectInput.value).toBe('')
  })

  it('clears the value of the select and autocomplete elements when hitting enter on the clear button', async function () {
    const clearButton = component.querySelector('.autocomplete__clear-button')
    clearButton.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }))
    await wait()

    expect(selectInput.value).toBe('')
  })
})

const wait = async () => await new Promise(resolve => setTimeout(resolve, 100))
