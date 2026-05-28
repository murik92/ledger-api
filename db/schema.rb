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

ActiveRecord::Schema[7.1].define(version: 2026_05_28_113743) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.bigint "balance_cents", null: false
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "opening_balance_cents", default: 0, null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_accounts_on_user_id"
    t.check_constraint "name::text = 'SYSTEM'::text OR balance_cents >= 0", name: "accounts_balance_non_negative"
    t.check_constraint "opening_balance_cents >= 0", name: "accounts_opening_balance_non_negative"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.string "entity_type", null: false
    t.bigint "entity_id", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["entity_type", "entity_id"], name: "index_audit_logs_on_entity_type_and_entity_id"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "category_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name", "category_type"], name: "index_categories_uniqueness", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "categorized_transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "ledger_transaction_id", null: false
    t.bigint "category_id", null: false
    t.string "transaction_type", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_categorized_transactions_on_category_id"
    t.index ["ledger_transaction_id"], name: "index_categorized_transactions_on_ledger_transaction_id"
    t.index ["ledger_transaction_id"], name: "index_unique_categorized_transaction", unique: true
    t.index ["user_id"], name: "index_categorized_transactions_on_user_id"
  end

  create_table "entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "ledger_transaction_id", null: false
    t.bigint "amount_cents", null: false
    t.string "entry_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_entries_on_account_id"
    t.index ["ledger_transaction_id"], name: "index_entries_on_ledger_transaction_id"
    t.check_constraint "amount_cents <> 0", name: "entries_amount_non_zero"
    t.check_constraint "entry_type::text = ANY (ARRAY['debit'::character varying, 'credit'::character varying]::text[])", name: "entries_valid_entry_type"
  end

  create_table "ledger_transactions", force: :cascade do |t|
    t.string "reference", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "idempotency_key"
    t.string "request_fingerprint"
    t.index ["idempotency_key"], name: "index_ledger_transactions_on_idempotency_key", unique: true
    t.index ["request_fingerprint"], name: "index_ledger_transactions_on_request_fingerprint"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying]::text[])", name: "ledger_transactions_valid_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "wallets", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "account_id", null: false
    t.string "currency", null: false
    t.string "status", default: "active", null: false
    t.string "wallet_type", default: "user", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_wallets_on_account_id"
    t.index ["name", "currency"], name: "index_system_wallets_unique", unique: true, where: "((wallet_type)::text = 'system'::text)"
    t.index ["user_id", "currency"], name: "index_user_wallets_on_currency_unique", unique: true, where: "((wallet_type)::text = 'user'::text)"
    t.index ["user_id"], name: "index_wallets_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'frozen'::character varying, 'archived'::character varying]::text[])", name: "wallets_valid_status"
    t.check_constraint "wallet_type::text = ANY (ARRAY['user'::character varying, 'system'::character varying]::text[])", name: "wallets_valid_type"
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "categorized_transactions", "categories"
  add_foreign_key "categorized_transactions", "ledger_transactions"
  add_foreign_key "categorized_transactions", "users"
  add_foreign_key "entries", "accounts"
  add_foreign_key "entries", "ledger_transactions"
  add_foreign_key "wallets", "accounts"
  add_foreign_key "wallets", "users"
end
