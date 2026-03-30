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

ActiveRecord::Schema[8.1].define(version: 2026_03_30_030745) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "coffee_tasting_notes", force: :cascade do |t|
    t.bigint "coffee_id", null: false
    t.datetime "created_at", null: false
    t.bigint "tasting_note_id", null: false
    t.datetime "updated_at", null: false
    t.index ["coffee_id", "tasting_note_id"], name: "index_coffee_tasting_notes_on_coffee_id_and_tasting_note_id", unique: true
    t.index ["coffee_id"], name: "index_coffee_tasting_notes_on_coffee_id"
    t.index ["tasting_note_id"], name: "index_coffee_tasting_notes_on_tasting_note_id"
  end

  create_table "coffees", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "origin", null: false
    t.integer "position", default: 0, null: false
    t.integer "price_cents", null: false
    t.integer "roast_level", default: 2, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_coffees_on_active"
    t.index ["position"], name: "index_coffees_on_position"
    t.index ["roast_level"], name: "index_coffees_on_roast_level"
    t.index ["slug"], name: "index_coffees_on_slug", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "payment_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "processor", null: false
    t.string "processor_customer_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "processor"], name: "index_payment_profiles_on_user_id_and_processor", unique: true
    t.index ["user_id"], name: "index_payment_profiles_on_user_id"
  end

  create_table "tasting_notes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tasting_notes_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "coffee_tasting_notes", "coffees"
  add_foreign_key "coffee_tasting_notes", "tasting_notes"
  add_foreign_key "payment_profiles", "users"
end
