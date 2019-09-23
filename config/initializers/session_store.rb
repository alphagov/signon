# Be sure to restart your server when you modify this file.

Signon::Application.config.session_store :cookie_store, key: "_signonotron2_session",
                                                secure: Rails.env.production?,
                                                httponly: true
