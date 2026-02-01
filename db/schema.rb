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

ActiveRecord::Schema[7.2].define(version: 2026_02_01_190225) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "conversations", force: :cascade do |t|
    t.bigint "scraping_id", null: false
    t.string "thread_id", null: false
    t.string "status", default: "active", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["metadata"], name: "index_conversations_on_metadata", using: :gin
    t.index ["scraping_id"], name: "index_conversations_on_scraping_id"
    t.index ["status"], name: "index_conversations_on_status"
    t.index ["thread_id"], name: "index_conversations_on_thread_id", unique: true
  end

  create_table "instagram_posts", force: :cascade do |t|
    t.bigint "scraping_id", null: false
    t.string "instagram_id", null: false
    t.string "short_code"
    t.string "post_type"
    t.text "caption"
    t.string "url"
    t.text "alt"
    t.integer "likes_count", default: 0
    t.integer "comments_count", default: 0
    t.integer "video_view_count"
    t.integer "video_play_count"
    t.decimal "video_duration"
    t.datetime "posted_at"
    t.integer "dimensions_height"
    t.integer "dimensions_width"
    t.text "display_url"
    t.text "video_url"
    t.text "audio_url"
    t.text "transcription"
    t.string "transcription_status", default: "pending"
    t.string "owner_username"
    t.string "owner_full_name"
    t.string "owner_id"
    t.boolean "is_pinned", default: false
    t.boolean "is_comments_disabled", default: false
    t.boolean "is_sponsored", default: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "assembly_transcript_id"
    t.index ["assembly_transcript_id"], name: "idx_posts_assembly_transcript", where: "(assembly_transcript_id IS NOT NULL)"
    t.index ["instagram_id"], name: "index_instagram_posts_on_instagram_id", unique: true
    t.index ["likes_count"], name: "index_instagram_posts_on_likes_count"
    t.index ["metadata"], name: "index_instagram_posts_on_metadata", using: :gin
    t.index ["owner_username"], name: "index_instagram_posts_on_owner_username"
    t.index ["post_type"], name: "index_instagram_posts_on_post_type"
    t.index ["posted_at"], name: "index_instagram_posts_on_posted_at"
    t.index ["scraping_id", "transcription_status"], name: "idx_posts_scraping_transcription", where: "(video_url IS NOT NULL)"
    t.index ["scraping_id"], name: "index_instagram_posts_on_scraping_id"
    t.index ["transcription_status"], name: "index_instagram_posts_on_transcription_status"
    t.index ["video_view_count"], name: "index_instagram_posts_on_video_view_count"
  end

  create_table "message_attachments", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.string "file_id", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.integer "file_size"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_id"], name: "index_message_attachments_on_file_id"
    t.index ["message_id"], name: "index_message_attachments_on_message_id"
    t.index ["metadata"], name: "index_message_attachments_on_metadata", using: :gin
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.string "role", null: false
    t.text "content", null: false
    t.string "message_id"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["message_id"], name: "index_messages_on_message_id"
    t.index ["metadata"], name: "index_messages_on_metadata", using: :gin
    t.index ["role"], name: "index_messages_on_role"
  end

  create_table "scraping_analyses", force: :cascade do |t|
    t.bigint "scraping_id", null: false
    t.text "analysis_text", null: false
    t.string "assistant_id"
    t.string "vector_store_id"
    t.string "file_id"
    t.string "status", default: "pending", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "chat_provider", default: "openai"
    t.index ["assistant_id"], name: "index_scraping_analyses_on_assistant_id"
    t.index ["chat_provider"], name: "index_scraping_analyses_on_chat_provider"
    t.index ["created_at"], name: "index_scraping_analyses_on_created_at"
    t.index ["metadata"], name: "index_scraping_analyses_on_metadata", using: :gin
    t.index ["scraping_id"], name: "index_scraping_analyses_on_scraping_id"
    t.index ["status"], name: "index_scraping_analyses_on_status"
  end

  create_table "scrapings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "profile_url"
    t.integer "results_limit"
    t.string "status"
    t.string "status_message"
    t.bigint "scraping_id"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_scrapings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "manus_api_key"
    t.string "anthropic_api_key"
    t.string "preferred_chat_api"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["preferred_chat_api"], name: "index_users_on_preferred_chat_api"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "conversations", "scrapings"
  add_foreign_key "instagram_posts", "scrapings"
  add_foreign_key "message_attachments", "messages"
  add_foreign_key "messages", "conversations"
  add_foreign_key "scraping_analyses", "scrapings"
  add_foreign_key "scrapings", "users"
end
