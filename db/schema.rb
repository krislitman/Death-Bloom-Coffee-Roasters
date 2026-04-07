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

ActiveRecord::Schema[8.1].define(version: 2026_04_07_021252) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "coffee_id", null: false
    t.datetime "created_at", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "coffee_id"], name: "index_cart_items_on_cart_id_and_coffee_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["coffee_id"], name: "index_cart_items_on_coffee_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "session_token"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["session_token"], name: "index_carts_on_session_token", unique: true
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

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

  create_table "newsletter_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "subscribed_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_newsletter_subscriptions_on_email", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "coffee_id", null: false
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["coffee_id"], name: "index_order_items_on_coffee_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "order_number", null: false
    t.string "shipping_address_city"
    t.string "shipping_address_line1"
    t.string "shipping_address_state"
    t.string "shipping_address_zip"
    t.integer "status", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["user_id"], name: "index_orders_on_user_id"
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
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "uid"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "coffees"
  add_foreign_key "carts", "users"
  add_foreign_key "coffee_tasting_notes", "coffees"
  add_foreign_key "coffee_tasting_notes", "tasting_notes"
  add_foreign_key "order_items", "coffees"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "users"
  add_foreign_key "payment_profiles", "users"
end
