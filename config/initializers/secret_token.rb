# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.

# NOTE: For Rails 4.2 this should be moved to secrets.yml. We're not doing that work during the
# Rails 4.1.11 upgrade because deployment currently needs to simultaenously support the Rails 3.2.x
# version of this, so we're purposefully kicking the can down the road.
Signonotron2::Application.config.secret_key_base = '101615e3369d108c13f7182caf9bb988fc8f2d8d309ebd16d39b34bece4b4bd0944df576bfa2ff35984e7c447658cc25810540b50759c15c2b94f8ef26867a8a'
