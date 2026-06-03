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

ActiveRecord::Schema[8.1].define(version: 2026_06_03_000200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "docker_containers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "docker_id", null: false
    t.string "image"
    t.text "import_error"
    t.string "import_status", default: "idle", null: false
    t.datetime "last_imported_at"
    t.datetime "log_cursor_at"
    t.string "name", null: false
    t.boolean "skip_analysis", default: false, null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_docker_containers_on_active"
    t.index ["docker_id"], name: "index_docker_containers_on_docker_id", unique: true
    t.index ["import_status"], name: "index_docker_containers_on_import_status"
    t.index ["name"], name: "index_docker_containers_on_name"
    t.index ["skip_analysis"], name: "index_docker_containers_on_skip_analysis"
  end

  create_table "inference_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "inference_prompt", null: false
    t.datetime "updated_at", null: false
  end

  create_table "log_entries", force: :cascade do |t|
    t.text "analysis_error"
    t.string "analysis_status", default: "pending", null: false
    t.datetime "analyzed_at"
    t.string "classification"
    t.datetime "created_at", null: false
    t.string "fingerprint", null: false
    t.datetime "first_seen_at", null: false
    t.jsonb "fixes", default: [], null: false
    t.datetime "last_seen_at", null: false
    t.text "message", null: false
    t.boolean "needs_action", default: false, null: false
    t.text "normalized_message"
    t.integer "occurrence_count", default: 1, null: false
    t.jsonb "other_suggestions", default: [], null: false
    t.jsonb "raw_payload", default: {}, null: false
    t.string "source_container", null: false
    t.string "stream", default: "stdout", null: false
    t.datetime "updated_at", null: false
    t.string "urgency"
    t.index ["analysis_status"], name: "index_log_entries_on_analysis_status"
    t.index ["classification"], name: "index_log_entries_on_classification"
    t.index ["fingerprint"], name: "index_log_entries_on_fingerprint", unique: true
    t.index ["last_seen_at"], name: "index_log_entries_on_last_seen_at"
    t.index ["needs_action"], name: "index_log_entries_on_needs_action"
    t.index ["normalized_message"], name: "index_log_entries_on_normalized_message"
  end
end
