window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  function Table ($module) {
    this.$module = $module
    this.searchInput = $module.querySelector('input[name="filter"]')
    this.tableRows = $module.querySelectorAll('.js-govuk-table__row')
    this.filter = $module.querySelector('.js-app-c-table__filter')
    this.filterCount = this.filter.querySelector('.js-filter-count')
    this.message = $module.querySelector('.js-app-c-table__message')
    this.hiddenClass = 'govuk-!-display-none'
    this.filterCountText = this.filterCount.getAttribute('data-count-text')
    this.tableRowsContent = []

    for (var i = 0; i < this.tableRows.length; i++) {
      this.tableRowsContent.push(this.tableRows[i].textContent.toUpperCase())
    }
  }

  Table.prototype.init = function () {
    this.$module.updateRows = this.updateRows.bind(this)
    this.filter.classList.remove(this.hiddenClass)
    this.searchInput.addEventListener('input', this.$module.updateRows)
  }

  // Reads value of input and filters content
  Table.prototype.updateRows = function () {
    var value = this.searchInput.value
    var hiddenRows = 0
    var length = this.tableRows.length

    for (var i = 0; i < length; i++) {
      if (this.tableRowsContent[i].includes(value.toUpperCase())) {
        this.tableRows[i].classList.remove(this.hiddenClass)
      } else {
        this.tableRows[i].classList.add(this.hiddenClass)
        hiddenRows++
      }
    }

    this.filterCount.textContent = (length - hiddenRows) + ' ' + this.filterCountText

    if (length === hiddenRows) {
      this.message.classList.remove(this.hiddenClass)
    } else {
      this.message.classList.add(this.hiddenClass)
    }
  }

  Modules.Table = Table
})(window.GOVUK.Modules)
