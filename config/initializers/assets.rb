# Be sure to restart your server when you modify this file.

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w[
  legacy_layout.css
  legacy_layout.js
  password-strength-indicator.js
  print.css
]

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Enable the asset pipeline
Rails.application.config.assets.enabled = true

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
