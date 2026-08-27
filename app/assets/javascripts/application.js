//= require govuk_publishing_components/dependencies
//= require govuk_publishing_components/lib
//= require govuk_publishing_components/components/copy-to-clipboard
//= require govuk_publishing_components/components/file-upload
//= require govuk_publishing_components/components/govspeak
//= require govuk_publishing_components/components/option-select
//= require govuk_publishing_components/components/password-input
//= require govuk_publishing_components/components/service-navigation
//= require govuk_publishing_components/components/table

//= require ./domain-config
//= require_tree ./modules
//= require_tree ./components
//= require rails-ujs

window.GOVUK.approveAllCookieTypes()
window.GOVUK.cookie('cookies_preferences_set', 'true', { days: 365 })
