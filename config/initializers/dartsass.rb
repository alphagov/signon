Rails.application.config.dartsass.build_options << " --quiet-deps"

if Rails.env.development?
  Rails.application.config.dartsass.builds.merge!(
    GovukPublishingComponents::Config.component_guide_stylesheet,
  )
end
