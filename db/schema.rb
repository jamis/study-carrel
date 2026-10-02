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

ActiveRecord::Schema[8.1].define(version: 2026_10_02_145817) do
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
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "works", force: :cascade do |t|
    t.string "title", null: false
    t.string "edition"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_works_on_slug", unique: true
  end

  add_foreign_key "sections", "works"
  add_foreign_key "sessions", "users"
  add_foreign_key "units", "sections"
end
