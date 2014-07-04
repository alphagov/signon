//= require zxcvbn
//= require jquery-debounce

(function() {
  "use strict"
  var root = this,
      $ = root.jQuery;

  if(typeof root.GOVUK === 'undefined') { root.GOVUK = {}; }

  var PasswordStrengthIndicator = function(options) {
    var instance = this;

    $.each([options["password_field"], options["password_confirmation_field"]], function(i, password_field) {
      var update = function() {
        var password = $(options["password_field"]).val(),
            passwordConfirmation = $(options["password_confirmation_field"]).val();
        instance.updateIndicator(password, passwordConfirmation, options);
      };
      $(password_field).debounce("keyup", update, 50);
    });

    $(options["password_strength_guidance"]).attr("aria-live", "polite").attr("aria-atomic", "true");
  };

  PasswordStrengthIndicator.prototype.updateIndicator = function(password, passwordConfirmation, options) {
    var guidance = [];

    var result = zxcvbn(password, options["weak_words"]);
    if (password.length > 0) {
      if (options["min_password_length"] && password.length < parseInt(options["min_password_length"])) {
        guidance.push('password-too-short');
      }

      var isPasswordNotStrongEnough = (result.score < options["strong_passphrase_boundary"]);

      var aWeakWordFoundInPassword = $(options["weak_words"]).is(function(i, weak_word) {
        return (password.indexOf(weak_word) >= 0);
      });
      if (isPasswordNotStrongEnough && aWeakWordFoundInPassword) {
        guidance.push('parts-of-email');
      }

      if (isPasswordNotStrongEnough) {
        guidance.push('not-strong-enough');
      } else {
        guidance.push('good-password');
      }
    }

    if (passwordConfirmation.length > 0) {
      if (password === passwordConfirmation) {
        guidance.push("confirmation-matching");
      } else {
        guidance.push("confirmation-not-matching");
      }
    } else {
      guidance.push("no-password-confirmation-provided");
    }

    options["update_indicator"](guidance, result.score);
  };

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

  GOVUK.passwordStrengthIndicator = PasswordStrengthIndicator;
}).call(this);

$(function() {
  $("form #password-control-group input[type=password]").each(function(){
    var $passwordChangePanel = $('#password-change-panel');

    var $passwordField = $(this);
    var $passwordConfirmationField = $("form #password-confirmation-control-group input[type=password]");
    $passwordField.parent().parent().append('<input type="hidden" id="password-strength-score" name="password-strength-score" value=""/>');

    new GOVUK.passwordStrengthIndicator({
      password_field: $passwordField,
      password_strength_guidance: $('#password-guidance'),
      password_confirmation_field: $passwordConfirmationField,
      password_confirmation_guidance: $('#password-confirmation-guidance'),

      weak_words: $passwordField.data('weak-words').split(","),
      strong_passphrase_boundary: 4,
      min_password_length: $passwordField.data('min-password-length'),

      update_indicator: function(guidance, strengthScore) {
        $('#password-strength-score').val(strengthScore);

        $passwordChangePanel.removeClass(GOVUK.passwordStrengthPossibleGuidance.join(" "));
        $passwordChangePanel.addClass(guidance.join(" "));

        if ($passwordField.val().length == 0) {
          $passwordField.attr('aria-invalid', "true");
          $('#password-result').removeClass('glyphicon-remove').addClass('glyphicon-ok');
        } else if ($.inArray('good-password', guidance) >= 0) {
          $passwordField.attr('aria-invalid', "false");
          $('#password-result').removeClass('glyphicon-remove').addClass('glyphicon glyphicon-ok');
        } else {
          $passwordField.attr('aria-invalid', "true");
          $('#password-result').removeClass('glyphicon glyphicon-ok').addClass('glyphicon glyphicon-remove');
        }

        $passwordChangePanel.removeClass(GOVUK.passwordConfirmationPossibleGuidance.join(" "));
        $passwordChangePanel.addClass(guidance.join(" "));

        var indicator = $('#password-confirmation-result');

        if ($passwordConfirmationField.val().length == 0) {
          indicator.attr('aria-invalid', "true");
          indicator.removeClass('glyphicon-remove').addClass('glyphicon-ok');
        } else if ($.inArray('confirmation-not-matching', guidance) >= 0) {
          $passwordConfirmationField.attr('aria-invalid', "true");
          indicator.removeClass('glyphicon glyphicon-ok').addClass('glyphicon glyphicon-remove');
          indicator.parent().removeClass('confirmation-matching');
        } else if ($.inArray('confirmation-matching', guidance) >= 0) {
          $passwordConfirmationField.attr('aria-invalid', "false");
          indicator.removeClass('glyphicon glyphicon-remove');
          // Add tick only if password field is also valid.
          if($.inArray('good-password', guidance) >= 0) {
            indicator.addClass('glyphicon glyphicon-ok');
            indicator.parent().addClass('confirmation-matching');
          }
        }
      }
    });
  });
});
