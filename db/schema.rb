# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150811150231) do

  create_table "batch_invitation_application_permissions", force: :cascade do |t|
    t.integer  "batch_invitation_id",     limit: 4, null: false
    t.integer  "supported_permission_id", limit: 4, null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "batch_invitation_application_permissions", ["batch_invitation_id", "supported_permission_id"], name: "index_batch_invite_app_perms_on_batch_invite_and_supported_perm", unique: true, using: :btree

  create_table "batch_invitation_users", force: :cascade do |t|
    t.integer  "batch_invitation_id", limit: 4
    t.string   "name",                limit: 255
    t.string   "email",               limit: 255
    t.string   "outcome",             limit: 255
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "batch_invitation_users", ["batch_invitation_id"], name: "index_batch_invitation_users_on_batch_invitation_id", using: :btree

  create_table "batch_invitations", force: :cascade do |t|
    t.text     "applications_and_permissions", limit: 65535
    t.string   "outcome",                      limit: 255
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "user_id",                      limit: 4,     null: false
    t.integer  "organisation_id",              limit: 4
  end

  add_index "batch_invitations", ["outcome"], name: "index_batch_invitations_on_outcome", using: :btree

  create_table "event_logs", force: :cascade do |t|
    t.string   "uid",              limit: 255, null: false
    t.string   "event",            limit: 255, null: false
    t.datetime "created_at",                   null: false
    t.integer  "initiator_id",     limit: 4
    t.integer  "application_id",   limit: 4
    t.string   "trailing_message", limit: 255
  end

  add_index "event_logs", ["uid", "created_at"], name: "index_event_logs_on_uid_and_created_at", using: :btree

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4,   null: false
    t.integer  "application_id",    limit: 4,   null: false
    t.string   "token",             limit: 255, null: false
    t.integer  "expires_in",        limit: 4,   null: false
    t.string   "redirect_uri",      limit: 255, null: false
    t.datetime "created_at",                    null: false
    t.datetime "revoked_at"
    t.string   "scopes",            limit: 255
  end

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4,   null: false
    t.integer  "application_id",    limit: 4,   null: false
    t.string   "token",             limit: 255, null: false
    t.string   "refresh_token",     limit: 255
    t.integer  "expires_in",        limit: 4
    t.datetime "revoked_at"
    t.datetime "created_at",                    null: false
    t.string   "scopes",            limit: 255
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.string   "uid",                   limit: 255,                null: false
    t.string   "secret",                limit: 255,                null: false
    t.string   "redirect_uri",          limit: 255,                null: false
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "home_uri",              limit: 255
    t.string   "description",           limit: 255
    t.boolean  "supports_push_updates",             default: true
  end

  add_index "oauth_applications", ["name"], name: "unique_application_name", unique: true, using: :btree
  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "old_passwords", force: :cascade do |t|
    t.string   "encrypted_password",       limit: 255, null: false
    t.string   "password_salt",            limit: 255
    t.integer  "password_archivable_id",   limit: 4,   null: false
    t.string   "password_archivable_type", limit: 255, null: false
    t.datetime "created_at"
  end

  add_index "old_passwords", ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable", using: :btree

  create_table "organisations", force: :cascade do |t|
    t.string   "slug",              limit: 255,                 null: false
    t.string   "name",              limit: 255,                 null: false
    t.string   "organisation_type", limit: 255,                 null: false
    t.string   "abbreviation",      limit: 255
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.string   "ancestry",          limit: 255
    t.string   "content_id",        limit: 255,                 null: false
    t.boolean  "closed",                        default: false
  end

  add_index "organisations", ["ancestry"], name: "index_organisations_on_ancestry", using: :btree
  add_index "organisations", ["content_id"], name: "index_organisations_on_content_id", unique: true, using: :btree
  add_index "organisations", ["slug"], name: "index_organisations_on_slug", unique: true, using: :btree

  create_table "supported_permissions", force: :cascade do |t|
    t.integer  "application_id",    limit: 4
    t.string   "name",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "delegatable",                   default: false
    t.boolean  "grantable_from_ui",             default: true,  null: false
  end

  add_index "supported_permissions", ["application_id", "name"], name: "index_supported_permissions_on_application_id_and_name", unique: true, using: :btree
  add_index "supported_permissions", ["application_id"], name: "index_supported_permissions_on_application_id", using: :btree

  create_table "user_application_permissions", force: :cascade do |t|
    t.integer  "user_id",                 limit: 4, null: false
    t.integer  "application_id",          limit: 4, null: false
    t.integer  "supported_permission_id", limit: 4, null: false
    t.datetime "last_synced_at"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "user_application_permissions", ["user_id", "application_id", "supported_permission_id"], name: "index_app_permissions_on_user_and_app_and_supported_permission", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name",                         limit: 255,                    null: false
    t.string   "email",                        limit: 255, default: "",       null: false
    t.string   "encrypted_password",           limit: 255, default: ""
    t.string   "reset_password_token",         limit: 255
    t.datetime "reset_password_sent_at"
    t.integer  "sign_in_count",                limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",           limit: 255
    t.string   "last_sign_in_ip",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uid",                          limit: 255,                    null: false
    t.integer  "failed_attempts",              limit: 4,   default: 0
    t.datetime "locked_at"
    t.datetime "suspended_at"
    t.string   "invitation_token",             limit: 255
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit",             limit: 4
    t.integer  "invited_by_id",                limit: 4
    t.string   "invited_by_type",              limit: 255
    t.string   "reason_for_suspension",        limit: 255
    t.string   "password_salt",                limit: 255
    t.string   "confirmation_token",           limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",            limit: 255
    t.string   "role",                         limit: 255, default: "normal"
    t.datetime "password_changed_at"
    t.integer  "organisation_id",              limit: 4
    t.boolean  "api_user",                                 default: false,    null: false
    t.datetime "unsuspended_at"
    t.datetime "invitation_created_at"
    t.string   "otp_secret_key",               limit: 255
    t.integer  "second_factor_attempts_count", limit: 4,   default: 0
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["organisation_id"], name: "index_users_on_organisation_id", using: :btree
  add_index "users", ["otp_secret_key"], name: "index_users_on_otp_secret_key", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
