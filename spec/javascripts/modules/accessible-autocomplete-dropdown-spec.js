describe('GOVUK.Modules.AccessibleAutocomplete', function () {
  let component, module

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
})

const wait = async () => await new Promise(resolve => setTimeout(resolve, 100))
