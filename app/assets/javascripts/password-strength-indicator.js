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
  };

  PasswordStrengthIndicator.prototype.updateStrengthIndicator = function(password, options) {
    var guidance = [];

    var result = zxcvbn(password, options["weak_words"]);
    if (password.length > 0) {
      if (options["min_password_length"] && password.length < parseInt(options["min_password_length"])) {
        guidance.push('password_too_short');
      }

      /* this isn't quite correct */
      if ($.inArray(password, options["weak_words"]) >= 0) {
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
}).call(this);

$(function() {
  var $passwordField = $("form #password-control-group input[type=password]");
  var passwordStrengthGuidance = $('#password-guidance');
  var $parent = $passwordField.parent();

  passwordStrengthGuidance.hide();

  new GOVUK.passwordStrengthIndicator({
    password_field: $passwordField,
    password_strength_guidance: passwordStrengthGuidance,

    weak_words: $passwordField.data('weak-words').split(","),
    strong_passphrase_boundary: 4,
    min_password_length: $passwordField.data('min-password-length'),

    update_indicator: function(guidance) {
      if ($.inArray('no_password_provided', guidance) >= 0) {
        passwordStrengthGuidance.hide();
        $('#password-result-span').hide();
      } else if ( guidance.length === 0 ) { /* success */
        passwordStrengthGuidance.hide();
        $('#password-result-span').show();
        $('#password-result').removeClass('icon-remove').addClass('icon-ok');
      } else {
        passwordStrengthGuidance.show();
        $('#password-result-span').show();
        $('#password-result').removeClass('icon-ok').addClass('icon-remove');

        $('#password-entropy').toggle($.inArray('not_strong_enough', guidance) >= 0);
        $('#password-too-short').toggle($.inArray('password_too_short', guidance) >= 0);
        $('#parts-of-email').toggle($.inArray('parts_of_email', guidance) >= 0);
      }
    }
  });
});
