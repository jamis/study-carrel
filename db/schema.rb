# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_05_120000) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "collections", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "position", default: 0, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.boolean "single_work", default: false, null: false
    t.index ["parent_id"], name: "index_collections_on_parent_id"
    t.index ["slug"], name: "index_collections_on_slug", unique: true
  end

  create_table "foci", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_unit_id"
    t.integer "user_id", null: false
    t.index ["last_unit_id"], name: "index_foci_on_last_unit_id"
    t.index ["user_id", "archived_at", "created_at"], name: "index_foci_on_user_id_and_archived_at_and_created_at"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "token_digest", null: false
    t.integer "created_by_id", null: false
    t.string "label"
    t.datetime "expires_at", null: false
    t.datetime "redeemed_at"
    t.integer "redeemed_by_id"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_invitations_on_created_by_id"
    t.index ["redeemed_by_id"], name: "index_invitations_on_redeemed_by_id"
    t.index ["token_digest"], name: "index_invitations_on_token_digest", unique: true
  end

  create_table "keeps", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "unit_id", null: false
    t.string "remark"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "index_keeps_on_unit_id"
    t.index ["user_id", "unit_id"], name: "index_keeps_on_user_id_and_unit_id", unique: true
    t.index ["user_id"], name: "index_keeps_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.integer "unit_id", null: false
    t.integer "focus_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["focus_id", "unit_id"], name: "index_notes_on_focus_id_and_unit_id", unique: true
    t.index ["focus_id"], name: "index_notes_on_focus_id"
    t.index ["unit_id"], name: "index_notes_on_unit_id"
  end

  create_table "sections", force: :cascade do |t|
    t.integer "work_id", null: false
    t.integer "number", null: false
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_id", "number"], name: "index_sections_on_work_id_and_number", unique: true
    t.index ["work_id"], name: "index_sections_on_work_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "units", force: :cascade do |t|
    t.integer "section_id", null: false
    t.integer "number", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id", "number"], name: "index_units_on_section_id_and_number", unique: true
    t.index ["section_id"], name: "index_units_on_section_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "visits", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "unit_id", null: false
    t.datetime "visited_at", null: false
    t.index ["unit_id"], name: "index_visits_on_unit_id"
    t.index ["user_id", "unit_id"], name: "index_visits_on_user_id_and_unit_id", unique: true
    t.index ["user_id", "visited_at"], name: "index_visits_on_user_id_and_visited_at"
    t.index ["user_id"], name: "index_visits_on_user_id"
  end

  create_table "works", force: :cascade do |t|
    t.string "title", null: false
    t.string "edition"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "collection_id"
    t.integer "position", default: 0, null: false
    t.string "unit_name", default: "verse", null: false
    t.string "author"
    t.string "author_short"
    t.index ["collection_id"], name: "index_works_on_collection_id"
    t.index ["slug"], name: "index_works_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "collections", "collections", column: "parent_id", on_delete: :nullify
  add_foreign_key "foci", "units", column: "last_unit_id", on_delete: :nullify
  add_foreign_key "foci", "users"
  add_foreign_key "invitations", "users", column: "created_by_id"
  add_foreign_key "invitations", "users", column: "redeemed_by_id", on_delete: :nullify
  add_foreign_key "keeps", "units"
  add_foreign_key "keeps", "users"
  add_foreign_key "notes", "foci"
  add_foreign_key "notes", "units"
  add_foreign_key "sections", "works"
  add_foreign_key "sessions", "users"
  add_foreign_key "units", "sections"
  add_foreign_key "visits", "units"
  add_foreign_key "visits", "users"
  add_foreign_key "works", "collections"
end
