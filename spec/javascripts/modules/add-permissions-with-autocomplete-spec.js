// describe('GOVUK.Modules.AccessibleAutocomplete', function () {
//   let component, module

//   beforeEach(function () {
//     component = document.createElement('div')
//     component.setAttribute('data-module', 'accessible-autocomplete')
//     component.innerHTML = `
//       <label class="govuk-label govuk-label--m" for="new_permission_id">Add a permission</label>

//       <div id="hint-1234" class="gem-c-hint govuk-hint">
//         Search for the permission you want to add.

//         <select name="application[new_permission_id]" id="new_permission_id" class="govuk-select" aria-describedby="hint-1234">
//           <option value=""></option>
//           <option value="1">permission-1</option>
//           <option value="2">permission-2</option>
//           <option value="3">permission-3</option>
//           <option value="4">permission-4</option>
//           <option value="5">permission-5</option>
//           <option value="6">permission-6</option>
//           <option value="7">permission-7</option>
//           <option value="8">permission-8</option>
//           <option value="9">permission-9</option>
//         </select>
//       </div>
//     `
//     module = new GOVUK.Modules.AccessibleAutocomplete(component)
//     module.init()
//   })

//   it('updates the value of the select element when selected via the autocomplete element', function () {
//     const autocompleteInput = component.querySelector('.autocomplete__input')
//     autocompleteInput.value = 'per'

//     // not found
//     const firstAutocompleteListItem = component.querySelector('#new_permission_id__option--0')
//     firstAutocompleteListItem.click()

//     const selectInput = component.querySelector('select')
//     expect(selectInput.value).toBe(1)
//   })

//   // it('resets the value of the select element when the value of the autocomplete element no longer matches', function () {

//   // })

//   // it('clears the value of the select and autocomplete elements when clicking the clear button', function () {

//   // })
// })
