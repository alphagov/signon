window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  function TwoFactorValidationError (module) {
    this.module = module
  }

  TwoFactorValidationError.prototype.init = function () {
    this.module.oninvalid = function (event) {
      event.target.setCustomValidity('This code should contain 6 digits with no spaces')
    }

    this.module.oninput = function (event) {
      event.target.setCustomValidity('')
    }
  }

  Modules.TwoFactorValidationError = TwoFactorValidationError
})(window.GOVUK.Modules)
