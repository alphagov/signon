# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_09_03_120837) do

  create_table "batch_invitation_application_permissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "batch_invitation_id", null: false
    t.integer "supported_permission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_invitation_id", "supported_permission_id"], name: "index_batch_invite_app_perms_on_batch_invite_and_supported_perm", unique: true
  end

  create_table "batch_invitation_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "batch_invitation_id"
    t.string "name"
    t.string "email"
    t.string "outcome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "organisation_slug"
    t.index ["batch_invitation_id"], name: "index_batch_invitation_users_on_batch_invitation_id"
  end

  create_table "batch_invitations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.text "applications_and_permissions"
    t.string "outcome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "organisation_id"
    t.index ["outcome"], name: "index_batch_invitations_on_outcome"
  end

  create_table "bulk_grant_permission_set_application_permissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "bulk_grant_permission_set_id", null: false
    t.integer "supported_permission_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["bulk_grant_permission_set_id", "supported_permission_id"], name: "index_app_permissions_on_bulk_grant_permission_set", unique: true
  end

  create_table "bulk_grant_permission_sets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "outcome"
    t.integer "processed_users", default: 0, null: false
    t.integer "total_users", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "event_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "uid"
    t.datetime "created_at", null: false
    t.integer "initiator_id"
    t.integer "application_id"
    t.string "trailing_message"
    t.integer "event_id"
    t.decimal "ip_address", precision: 38
    t.integer "user_agent_id"
    t.string "user_agent_string"
    t.string "user_email_string"
    t.index ["uid", "created_at"], name: "index_event_logs_on_uid_and_created_at"
    t.index ["user_agent_id"], name: "event_logs_user_agent_id_fk"
  end

  create_table "lhma_2019_04_29_13_15_20_064_event_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.integer "initiator_id"
    t.integer "application_id"
    t.string "trailing_message"
    t.integer "event_id"
    t.bigint "ip_address"
    t.integer "user_agent_id"
    t.index ["uid", "created_at"], name: "index_event_logs_on_uid_and_created_at"
    t.index ["user_agent_id"], name: "event_logs_user_agent_id_fk"
  end

  create_table "oauth_access_grants", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.string "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "name"
    t.string "uid", null: false
    t.string "secret", null: false
    t.string "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "home_uri"
    t.string "description"
    t.boolean "supports_push_updates", default: true
    t.boolean "retired", default: false
    t.boolean "show_on_dashboard", default: true, null: false
    t.boolean "confidential", default: true, null: false
    t.index ["name"], name: "unique_application_name", unique: true
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "old_passwords", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "encrypted_password", null: false
    t.string "password_salt"
    t.integer "password_archivable_id", null: false
    t.string "password_archivable_type", null: false
    t.datetime "created_at"
    t.index ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable"
  end

  create_table "organisations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.string "organisation_type", null: false
    t.string "abbreviation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ancestry"
    t.string "content_id", null: false
    t.boolean "closed", default: false
    t.index ["ancestry"], name: "index_organisations_on_ancestry"
    t.index ["content_id"], name: "index_organisations_on_content_id", unique: true
    t.index ["slug"], name: "index_organisations_on_slug", unique: true
  end

  create_table "supported_permissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "application_id"
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "delegatable", default: false
    t.boolean "grantable_from_ui", default: true, null: false
    t.boolean "default", default: false, null: false
    t.index ["application_id", "name"], name: "index_supported_permissions_on_application_id_and_name", unique: true
    t.index ["application_id"], name: "index_supported_permissions_on_application_id"
  end

  create_table "user_agents", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "user_agent_string", limit: 1000, null: false
    t.index ["user_agent_string"], name: "index_user_agents_on_user_agent_string", length: 255
  end

  create_table "user_application_permissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "application_id", null: false
    t.integer "supported_permission_id", null: false
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "application_id", "supported_permission_id"], name: "index_app_permissions_on_user_and_app_and_supported_permission", unique: true
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: ""
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "uid", null: false
    t.integer "failed_attempts", default: 0
    t.datetime "locked_at"
    t.datetime "suspended_at"
    t.string "invitation_token"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.string "reason_for_suspension"
    t.string "password_salt"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "role", default: "normal"
    t.datetime "password_changed_at"
    t.integer "organisation_id"
    t.boolean "api_user", default: false, null: false
    t.datetime "unsuspended_at"
    t.datetime "invitation_created_at"
    t.string "otp_secret_key"
    t.integer "second_factor_attempts_count", default: 0
    t.string "unlock_token"
    t.boolean "require_2sv", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["otp_secret_key"], name: "index_users_on_otp_secret_key", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "event_logs", "user_agents", name: "event_logs_user_agent_id_fk"
end
