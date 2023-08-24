//= require zxcvbn

window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  'use strict'

  function PasswordStrengthIndicator (module) {
    this.module = module
    this.passwordInput = this.module.querySelector('.password-control-group input')
    this.passwordConfirmationInput = this.module.querySelector('.password-confirmation-control-group input')
    this.strongPasswordBoundary = 4
    this.emailParts = this.passwordInput.getAttribute('data-email-parts').split(',')
    this.minimumPasswordLength = parseInt(this.passwordInput.getAttribute('data-min-password-length'))
    this.errorMessages = {
      'password-too-short': 'Your password must be at least ' + this.minimumPasswordLength + ' characters',
      'parts-of-email': 'Your password shouldn’t include part or all of your email address',
      'password-entropy': 'Your password must be more complex',
      'confirmation-not-matching': 'The confirmation must match the new password'
    }
  }

  PasswordStrengthIndicator.prototype.init = function () {
    this.passwordErrorContainer = this.createErrorContainer(
      this.module.querySelector('.password-control-group')
    )
    this.passwordConfirmationErrorContainer = this.createErrorContainer(
      this.module.querySelector('.password-confirmation-control-group')
    )

    this.passwordInput.addEventListener('input', this.checkInput.bind(this))
    this.passwordConfirmationInput.addEventListener('input', this.checkInput.bind(this))
  }

  PasswordStrengthIndicator.prototype.createErrorContainer = function (group) {
    var ul = document.createElement('ul')
    ul.className = 'govuk-error-message govuk-list'
    ul.setAttribute('aria-live', 'polite')
    ul.setAttribute('aria-atomic', 'true')
    ul.errors = []
    var label = group.querySelector('label')
    label.insertAdjacentElement('afterend', ul)
    return ul
  }

  PasswordStrengthIndicator.prototype.checkInput = function () {
    var passwordErrors = []
    var passwordConfirmationErrors = []

    if (this.passwordInput.value.length > 0) {
      if (this.passwordInput.value.length < this.minimumPasswordLength) {
        passwordErrors.push('password-too-short')
      }

      var notStrongEnough = this.passwordNotStrongEnough()

      if (notStrongEnough && this.passwordContainsEmailParts()) {
        passwordErrors.push('parts-of-email')
      }

      if (notStrongEnough) {
        passwordErrors.push('password-entropy')
      }
    }

    if (this.passwordConfirmationInput.value.length > 0) {
      if (this.passwordInput.value !== this.passwordConfirmationInput.value) {
        passwordConfirmationErrors.push('confirmation-not-matching')
      }
    }

    this.updateErrors(this.passwordErrorContainer, passwordErrors)
    this.updateErrors(this.passwordConfirmationErrorContainer, passwordConfirmationErrors)
  }

  PasswordStrengthIndicator.prototype.passwordContainsEmailParts = function () {
    for (var i = 0; i < this.emailParts.length; i++) {
      if (this.emailParts[i] === '') continue
      if (this.passwordInput.value.indexOf(this.emailParts[i]) >= 0) {
        return true
      }
    }

    return false
  }

  PasswordStrengthIndicator.prototype.passwordNotStrongEnough = function () {
    var result = window.zxcvbn(this.passwordInput.value, this.emailParts)

    return result.score < this.strongPasswordBoundary
  }

  PasswordStrengthIndicator.prototype.updateErrors = function (errorContainer, errors) {
    // crude array comparison
    if (errorContainer.errors.join(',') === errors.join(',')) return

    // remove existing errors
    while (errorContainer.firstChild) {
      errorContainer.removeChild(errorContainer.firstChild)
    }

    for (var i = 0; i < errors.length; i++) {
      var li = document.createElement('li')
      li.textContent = this.errorMessages[errors[i]]
      errorContainer.appendChild(li)
    }

    errorContainer.errors = errors
  }

  Modules.PasswordStrengthIndicator = PasswordStrengthIndicator
})(window.GOVUK.Modules)
