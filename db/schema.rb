ActiveRecord::Schema[8.1].define(version: 2026_05_19_000100) do
  enable_extension "plpgsql"

  create_table "log_entries", force: :cascade do |t|
    t.string "source_container", null: false
    t.string "stream", default: "stdout", null: false
    t.text "message", null: false
    t.string "fingerprint", null: false
    t.integer "occurrence_count", default: 1, null: false
    t.datetime "first_seen_at", null: false
    t.datetime "last_seen_at", null: false
    t.string "analysis_status", default: "pending", null: false
    t.text "analysis_error"
    t.datetime "analyzed_at"
    t.string "classification"
    t.string "urgency"
    t.boolean "needs_action", default: false, null: false
    t.jsonb "fixes", default: [], null: false
    t.jsonb "other_suggestions", default: [], null: false
    t.jsonb "raw_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["analysis_status"], name: "index_log_entries_on_analysis_status"
    t.index ["classification"], name: "index_log_entries_on_classification"
    t.index ["needs_action"], name: "index_log_entries_on_needs_action"
    t.index ["fingerprint"], name: "index_log_entries_on_fingerprint", unique: true
    t.index ["last_seen_at"], name: "index_log_entries_on_last_seen_at"
  end
end
