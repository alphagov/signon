# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Enable the asset pipeline
Rails.application.config.assets.enabled = true

# Add node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")
