window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  function AutoSubmitForm (module) {
    this.module = module
    this.module.ignore = this.module.getAttribute('data-auto-submit-ignore').split(',')
  }

  AutoSubmitForm.prototype.init = function () {
    this.module.addEventListener('change', function (e) {
      if (!this.module.ignore.includes(e.target.getAttribute('name'))) {
        this.module.submit()
      }
    }.bind(this))
  }

  Modules.AutoSubmitForm = AutoSubmitForm
})(window.GOVUK.Modules)
