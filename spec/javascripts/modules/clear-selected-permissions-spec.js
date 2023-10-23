describe('GOVUK.Modules.ClearSelectedPermissions', function () {
  let component, module

  beforeEach(function () {
    component = document.createElement('div')
    component.innerHTML = `
      <button type="submit" data-action="clear">Clear selected permissions</button>

      <ul class="gem-c-checkboxes__list">
        <li class="govuk-checkboxes__item">
          <input type="checkbox" class="govuk-checkboxes__input" checked="checked" />
        </li>
      </ul>
    `
    module = new GOVUK.Modules.ClearSelectedPermissions(component)
    module.init()
  })

  it('clears the checked status of the checkboxes when the button is clicked', function () {
    const input = component.querySelector('input')
    expect(input.checked).toBe(true)

    component.querySelector('button').click()

    expect(input.checked).toBe(false)
  })

  it('sends a change event to the checkbox list when the button is clicked', function () {
    const list = component.querySelector('ul')
    spyOn(list, 'dispatchEvent')

    component.querySelector('button').click()

    expect(list.dispatchEvent).toHaveBeenCalledWith(jasmine.objectContaining({ type: 'change' }))
  })
})
