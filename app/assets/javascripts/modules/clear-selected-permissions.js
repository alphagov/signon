window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  function ClearSelectedPermissions (module) {
    this.module = module
    this.clearButton = this.module.querySelector('button[data-action="clear"]')
    this.checkboxes = this.module.querySelectorAll('.govuk-checkboxes__input')
    this.checkboxLists = this.module.querySelectorAll('.gem-c-checkboxes__list')
  }

  ClearSelectedPermissions.prototype.init = function () {
    this.clearButton.addEventListener('click', this.clear.bind(this))
  }

  ClearSelectedPermissions.prototype.clear = function (event) {
    event.preventDefault()
    this.uncheckBoxes()
    this.updateSelectCounts()
  }

  ClearSelectedPermissions.prototype.uncheckBoxes = function () {
    this.checkboxes.forEach(c => { c.checked = false })
  }

  ClearSelectedPermissions.prototype.updateSelectCounts = function () {
    const event = new Event('change')
    this.checkboxLists.forEach(c => { c.dispatchEvent(event) })
  }

  Modules.ClearSelectedPermissions = ClearSelectedPermissions
})(window.GOVUK.Modules)
