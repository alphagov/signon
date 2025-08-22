'use strict'
window.GOVUK = window.GOVUK || {}
window.GOVUK.vars = window.GOVUK.vars || {}
window.GOVUK.vars.extraDomains = [
  {
    name: 'production',
    domains: ['signon.publishing.service.gov.uk'],
    initialiseGA4: true,
    id: 'GTM-P93SHJ4Z'
  },
  {
    name: 'staging',
    domains: ['signon.staging.publishing.service.gov.uk'],
    initialiseGA4: false
  },
  {
    name: 'integration',
    domains: ['signon.integration.publishing.service.gov.uk'],
    initialiseGA4: true,
    id: 'GTM-P93SHJ4Z',
    auth: '8jHx-VNEguw67iX9TBC6_g',
    preview: 'env-50'
  }
]
