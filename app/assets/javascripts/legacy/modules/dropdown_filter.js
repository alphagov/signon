(function (Modules) {
  'use strict'
  Modules.DropdownFilter = function () {
    var that = this
    that.start = function (element) {
      var list = element.find('.js-filter-list')
      var listItems = list.find('li:not(:first)')
      var listInput = element.find('.js-filter-list-input')

      // Prevent dropdowns with text inputs from closing when
      // interacting with them
      element.on('click', '.js-filter-list-input', function (event) { event.stopPropagation() })

      element.on('shown.bs.dropdown', focusInput)
      element.on('keyup change', '.js-filter-list-input', filterListBasedOnInput)
      element.on('submit', 'form', openFirstVisibleLink)

      // Set explicit width inline, so filtering doesn't change dropdown size
      list.width(list.width())

      function filterListBasedOnInput (event) {
        var searchString = $.trim(listInput.val())
        var regExp = new RegExp(searchString, 'i')

        listItems.each(function () {
          var item = $(this)
          if (item.text().search(regExp) > -1) {
            item.show()
          } else {
            item.hide()
          }
        })
      }

      function openFirstVisibleLink (evt) {
        evt.preventDefault()
        var link = list.find('a:visible').first()
        GOVUKAdmin.redirect(link.attr('href'))
      }

      function focusInput (event) {
        var container = $(event.target)
        setTimeout(function () {
          container.find('input[type="text"]').focus()
        }, 50)
      }
    }
  }
})(window.GOVUKAdmin.Modules)
