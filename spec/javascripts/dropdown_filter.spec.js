describe('A dropdown filter module', function () {
  'use strict'

  var dropdownFilter
  var listElement

  beforeEach(function () {
    listElement = $('<div>' +
      '<ul class="js-filter-list">' +
        '<li>' +
          '<form>' +
            '<input type="text" class="js-filter-list-input">' +
          '</form>' +
        '</li>' +
        '<li class="first">' +
          '<a href="/first-link">something</a>' +
        '</li>' +
        '<li class="second">' +
          '<a href="/second-link">another thing</a>' +
        '</li>' +
      '</ul>' +
    '</div>')

    $('body').append(listElement)
    dropdownFilter = new GOVUKAdmin.Modules.DropdownFilter()
    dropdownFilter.start(listElement)
  })

  afterEach(function () {
    listElement.remove()
  })

  it('filters the dropdown list based on input', function () {
    filterBy('another')
    expect(listElement.find('.first').is(':visible')).toBe(false)
    expect(listElement.find('.second').is(':visible')).toBe(true)

    filterBy('something')
    expect(listElement.find('.first').is(':visible')).toBe(true)
    expect(listElement.find('.second').is(':visible')).toBe(false)

    filterBy('thing')
    expect(listElement.find('.first').is(':visible')).toBe(true)
    expect(listElement.find('.second').is(':visible')).toBe(true)

    filterBy('not a thing')
    expect(listElement.find('.first').is(':visible')).toBe(false)
    expect(listElement.find('.second').is(':visible')).toBe(false)
  })

  it('keeps the first list item visible, the filter input', function () {
    filterBy('another')
    expect(listElement.find('li:first').is(':visible')).toBe(true)

    filterBy('')
    expect(listElement.find('li:first').is(':visible')).toBe(true)

    filterBy('not a thing')
    expect(listElement.find('li:first').is(':visible')).toBe(true)
  })

  it('shows all items when no input is entered', function () {
    filterBy('another')
    filterBy('')
    expect(listElement.find('.first').is(':visible')).toBe(true)
    expect(listElement.find('.second').is(':visible')).toBe(true)
  })

  describe('when the form is submitted', function () {
    it('opens the first visible link', function () {
      spyOn(GOVUKAdmin, 'redirect')
      filterBy('another')
      listElement.find('form').trigger('submit')
      expect(GOVUKAdmin.redirect).toHaveBeenCalledWith('/second-link')
    })
  })

  function filterBy (value) {
    listElement.find('input').val(value).trigger('change')
  }
})
