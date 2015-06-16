# Be sure to restart your server when you modify this file.

Signonotron2::Application.config.session_store :cookie_store, key: '_signonotron2_session',
                                                secure: Rails.env.production?
