//= require zxcvbn

(function () {
  'use strict'
  var root = this
  var $ = root.jQuery

  if (typeof root.GOVUK === 'undefined') { root.GOVUK = {} }

  var PasswordStrengthIndicator = function (options) {
    var instance = this

    $.each([options.password_field, options.password_confirmation_field], function (i, passwordField) {
      var update = function () {
        var password = $(options.password_field).val()
        var passwordConfirmation = $(options.password_confirmation_field).val()
        instance.updateIndicator(password, passwordConfirmation, options)
      }
      $(passwordField).on('input', update)
    })

    $(options.password_strength_guidance).attr('aria-live', 'polite').attr('aria-atomic', 'true')
  }

  PasswordStrengthIndicator.prototype.updateIndicator = function (password, passwordConfirmation, options) {
    var guidance = []

    var result = zxcvbn(password, options.weak_words)
    if (password.length > 0) {
      if (options.min_password_length && password.length < parseInt(options.min_password_length)) {
        guidance.push('password-too-short')
      }

      var isPasswordNotStrongEnough = (result.score < options.strong_password_boundary)

      var aWeakWordFoundInPassword = $(options.weak_words).is(function (i, weakWord) {
        return (password.indexOf(weakWord) >= 0)
      })
      if (isPasswordNotStrongEnough && aWeakWordFoundInPassword) {
        guidance.push('parts-of-email')
      }

      if (isPasswordNotStrongEnough) {
        guidance.push('not-strong-enough')
      } else {
        guidance.push('good-password')
      }
    }

    if (passwordConfirmation.length > 0) {
      if (password === passwordConfirmation) {
        guidance.push('confirmation-matching')
      } else {
        guidance.push('confirmation-not-matching')
      }
    } else {
      guidance.push('no-password-confirmation-provided')
    }

    options.update_indicator(guidance, result.score)
  }

  GOVUK.passwordStrengthPossibleGuidance = [
    'password-too-short',
    'parts-of-email',
    'not-strong-enough',
    'good-password'
  ]

  GOVUK.passwordConfirmationPossibleGuidance = [
    'confirmation-matching',
    'confirmation-not-matching',
    'no-password-confirmation-provided'
  ]

  GOVUK.passwordStrengthIndicator = PasswordStrengthIndicator
}).call(this)

$(function () {
  // Reposition the error messages between the label and input
  $('#password-guidance').detach().insertAfter('#password-control-group label')
  $('#password-confirmation-guidance').detach().insertAfter('#password-confirmation-control-group label')

  $('form #password-control-group input[type=password]').each(function () {
    var $passwordChangePanel = $('#password-change-panel')

    var $passwordField = $(this)
    var $passwordConfirmationField = $('form #password-confirmation-control-group input[type=password]')
    $passwordField.parent().parent().append('<input type="hidden" id="password-strength-score" name="password-strength-score" value=""/>')

    new GOVUK.passwordStrengthIndicator({ // eslint-disable-line no-new, new-cap
      password_field: $passwordField,
      password_strength_guidance: $('#password-guidance'),
      password_confirmation_field: $passwordConfirmationField,
      password_confirmation_guidance: $('#password-confirmation-guidance'),

      weak_words: $passwordField.data('weak-words').split(','),
      strong_password_boundary: 4,
      min_password_length: $passwordField.data('min-password-length'),

      update_indicator: function (guidance, strengthScore) {
        $('#password-strength-score').val(strengthScore)

        $passwordChangePanel.removeClass(GOVUK.passwordStrengthPossibleGuidance.join(' '))
        $passwordChangePanel.addClass(guidance.join(' '))

        $passwordChangePanel.removeClass(GOVUK.passwordConfirmationPossibleGuidance.join(' '))
        $passwordChangePanel.addClass(guidance.join(' '))
      }
    })
  })
})
