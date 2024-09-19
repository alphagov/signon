describe('GOVUK.Modules.AccessibleAutocomplete', function () {
  let component, module, autocompleteInput, selectInput

  beforeEach(async function () {
    component = document.createElement('div')
    component.setAttribute('data-module', 'accessible-autocomplete')
    component.innerHTML = `
    <form action="/whatever" method="post">
      <div class="govuk-form-group gem-c-select">
        <label class="govuk-label govuk-label--m" for="new_permission_id">Add a permission</label>
        <div id="hint-1234" class="gem-c-hint govuk-hint">
          Search for the permission you want to add.
        </div>
        <select name="application[new_permission_id]" id="new_permission_id" class="govuk-select" aria-describedby="hint-1234">
          <option value=""></option>
          <option value="1">permission-1</option>
          <option value="2">permission-2</option>
          <option value="3">permission-3</option>
        </select>
      </div>
      <input type="hidden" name="application[add_more]" id="application_add_more" value="false" autocomplete="off">
      <div class="govuk-button-group">
        <button class="gem-c-button govuk-button js-autocomplete__add-button" type="submit" aria-label="Add permission">Add</button>
        <button class="gem-c-button govuk-button js-autocomplete__add-and-finish-button" type="submit" aria-label="Add permission and finish">Add and finish</button>
        <button class="gem-c-button govuk-button govuk-button--secondary js-autocomplete__clear-button" type="button">Clear selection</button>
      </div>
    </form>
    `

    module = new GOVUK.Modules.AccessibleAutocomplete(component)
    module.init()

    autocompleteInput = component.querySelector('.autocomplete__input')
    selectInput = component.querySelector('select')

    autocompleteInput.value = 'per'
    await wait()

    expect(selectInput.value).toBe('')
    const firstAutocompleteListItem = component.querySelector('#new_permission_id__option--0')
    firstAutocompleteListItem.click()
    expect(autocompleteInput.value).toBe('permission-1')
    expect(selectInput.value).toBe('1')
  })

  it('opens the menu when clicking the arrow', async function () {
    const menuElement = component.querySelector('.autocomplete__menu')
    const menuElementClassesBefore = Array.from(menuElement.classList)
    expect(menuElementClassesBefore.includes('autocomplete__menu--visible')).toBe(false)
    expect(menuElementClassesBefore.includes('autocomplete__menu--hidden')).toBe(true)

    const arrowElement = component.querySelector('.autocomplete__dropdown-arrow-down')
    arrowElement.dispatchEvent(new Event('click'))

    await wait()

    const menuElementClassesAfter = Array.from(menuElement.classList)
    expect(menuElementClassesAfter.includes('autocomplete__menu--visible')).toBe(true)
    expect(menuElementClassesAfter.includes('autocomplete__menu--hidden')).toBe(false)
  })

  it("resets the value of the select element when it no longer matches what's shown in the autocomplete input", async function () {
    autocompleteInput.value = 'permission-'
    autocompleteInput.dispatchEvent(new KeyboardEvent('keyup'))
    await wait()

    expect(selectInput.value).toBe('')
  })

  it('clears the value of the select and autocomplete elements when clicking the clear button', async function () {
    const clearButton = component.querySelector('.js-autocomplete__clear-button')
    clearButton.click()
    await wait()

    expect(component.querySelector('select').value).toBe('')
  })

  it('clears the value of the select and autocomplete elements when hitting space on the clear button', async function () {
    const clearButton = component.querySelector('.js-autocomplete__clear-button')
    clearButton.dispatchEvent(new KeyboardEvent('keydown', { key: ' ' }))
    await wait()

    expect(selectInput.value).toBe('')
  })

  it('clears the value of the select and autocomplete elements when hitting enter on the clear button', async function () {
    const clearButton = component.querySelector('.js-autocomplete__clear-button')
    clearButton.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }))
    await wait()

    expect(selectInput.value).toBe('')
  })
})

const wait = async () => await new Promise(resolve => setTimeout(resolve, 100))
