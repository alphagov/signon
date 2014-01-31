//= require jquery
//= require zxcvbn

(function() {
  "use strict"
  var root = this,
      $ = root.jQuery;

  if(typeof root.GOVUK === 'undefined') { root.GOVUK = {}; }

  var PasswordStrengthIndicator = function(options) {
    var instance = this;

    options["password_field"].keyup(function() {
      var password = $(this).val();
      instance.updateStrengthIndicator(password, options);
    });

    $(options["password_strength_guidance"]).attr("aria-live", "polite");
    $(options["password_field"]).attr('aria-controls', $(options["password_strength_guidance"]).attr('id'));
  };

  PasswordStrengthIndicator.prototype.updateStrengthIndicator = function(password, options) {
    var guidance = [];

    var result = zxcvbn(password, options["weak_words"]);
    if (password.length > 0) {
      if (options["min_password_length"] && password.length < parseInt(options["min_password_length"])) {
        guidance.push('password_too_short');
      }

      var aWeakWordFoundInPassword = $(options["weak_words"]).is(function(i, weak_word) {
        return (password.indexOf(weak_word) >= 0);
      });
      if (aWeakWordFoundInPassword) {
        guidance.push('parts_of_email')
      }

      if (result.score < options["strong_passphrase_boundary"]) {
        guidance.push('not_strong_enough');
      }
    } else {
      guidance.push("no_password_provided");
    }
    options["update_indicator"](guidance);
  };

  GOVUK.passwordStrengthIndicator = PasswordStrengthIndicator;

  var PasswordConfirmationIndicator = function(options) {
    var instance = this;

    $.each([options["password_field"], options["password_confirmation_field"]], function(i, password_field) {
      $(password_field).keyup(function() {
        var password = $(options["password_field"]).val();
        var passwordConfirmation = $(options["password_confirmation_field"]).val();
        instance.updateIndicator(password, passwordConfirmation, options);
      });
    });

    $(options["password_confirmation_guidance"]).attr("aria-live", "polite");
    $(options["password_confirmation_field"]).attr('aria-controls', $(options["password_confirmation_guidance"]).attr('id'));
  };

  PasswordConfirmationIndicator.prototype.updateIndicator = function(password, passwordConfirmation, options) {
    var guidance = [];

    if (passwordConfirmation.length > 0) {
      if (password === passwordConfirmation) {
        guidance.push("confirmation_matching");
      } else {
        guidance.push("confirmation_not_matching");
      }
    } else {
      guidance.push("no_password_confirmation_provided");
    }

    options["update_indicator"](guidance);
  };

  GOVUK.passwordConfirmationIndicator = PasswordConfirmationIndicator;
}).call(this);

$(function() {
  $("form #password-control-group input[type=password]").each(function(){
    var $passwordField = $(this);
    var $passwordConfirmationField = $("form #password-confirmation-control-group input[type=password]");
    var $passwordStrengthGuidance = $('#password-guidance');
    var $passwordConfirmationGuidance = $('#password-confirmation-guidance');

    $passwordStrengthGuidance.hide();

    new GOVUK.passwordStrengthIndicator({
      password_field: $passwordField,
      password_strength_guidance: $passwordStrengthGuidance,

      weak_words: $passwordField.data('weak-words').split(","),
      strong_passphrase_boundary: 4,
      min_password_length: $passwordField.data('min-password-length'),

      update_indicator: function(guidance) {
        if ($.inArray('no_password_provided', guidance) >= 0) {
          $passwordStrengthGuidance.hide();
          $('#password-result-span').hide();
        } else if ( guidance.length === 0 ) { /* success */
          $passwordStrengthGuidance.hide();
          $('#password-result-span').show();
          $('#password-result').removeClass('icon-remove').addClass('icon-ok');
        } else {
          $passwordStrengthGuidance.show();
          $('#password-result-span').show();
          $('#password-result').removeClass('icon-ok').addClass('icon-remove');

          $('#password-entropy').toggle($.inArray('not_strong_enough', guidance) >= 0);
          $('#password-too-short').toggle($.inArray('password_too_short', guidance) >= 0);
          $('#parts-of-email').toggle($.inArray('parts_of_email', guidance) >= 0);
        }
      }
    });

    new GOVUK.passwordConfirmationIndicator({
      password_field: $passwordField,
      password_confirmation_field: $passwordConfirmationField,
      password_confirmation_guidance: $passwordConfirmationGuidance,
      update_indicator: function(guidance) {
        if ($.inArray('no_password_confirmation_provided', guidance) >= 0) {
          $passwordConfirmationGuidance.hide();
          $('#password-confirmation-result-span').hide();
        } else if ($.inArray('confirmation_not_matching', guidance) >= 0) {
          $passwordConfirmationGuidance.show();
          $('#password-confirmation-result-span').show();
          $('#password-confirmation-result').removeClass('icon-ok').addClass('icon-remove');
        } else { /* password and confirmation match */
          $passwordConfirmationGuidance.hide();
          $('#password-confirmation-result-span').show();
          $('#password-confirmation-result').removeClass('icon-remove').addClass('icon-ok');
        }
      }
    });
  });
});
