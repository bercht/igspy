# app/services/apify_json_processor_service.rb
class ApifyJsonProcessorService
  attr_reader :scraping, :json_data, :errors

  def initialize(scraping, json_data)
    @scraping = scraping
    @json_data = json_data
    @errors = []
  end

  def call
    return false unless validate_input

    process_posts
    
    @errors.empty?
  rescue StandardError => e
    Rails.logger.error "ApifyJsonProcessor error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @errors << e.message
    false
  end

  private

  def validate_input
    if json_data.blank?
      @errors << "JSON data is blank"
      return false
    end

    unless json_data.is_a?(Array)
      @errors << "JSON data must be an array"
      return false
    end

    true
  end

  def process_posts
    json_data.each do |post_data|
      process_single_post(post_data)
    end
  end

  def process_single_post(post_data)
    # Extrai dados principais
    instagram_id = post_data["id"]
    
    unless instagram_id
      @errors << "Post without ID: #{post_data.inspect[0..200]}"
      return
    end

    # Cria ou atualiza o post
    post = scraping.instagram_posts.find_or_initialize_by(instagram_id: instagram_id)
    
    post.assign_attributes(
      short_code: post_data["shortCode"],
      post_type: post_data["type"],
      caption: post_data["caption"],
      url: post_data["url"],
      alt: post_data["alt"],
      likes_count: post_data["likesCount"] || 0,
      comments_count: post_data["commentsCount"] || 0,
      video_view_count: post_data["videoViewCount"],
      video_play_count: post_data["videoPlayCount"],
      video_duration: post_data["videoDuration"],
      posted_at: parse_timestamp(post_data["timestamp"]),
      dimensions_height: post_data["dimensionsHeight"],
      dimensions_width: post_data["dimensionsWidth"],
      display_url: post_data["displayUrl"],
      video_url: post_data["videoUrl"],
      audio_url: post_data["audioUrl"],
      owner_username: post_data["ownerUsername"],
      owner_full_name: post_data["ownerFullName"],
      owner_id: post_data["ownerId"],
      is_pinned: post_data["isPinned"] || false,
      is_comments_disabled: post_data["isCommentsDisabled"] || false,
      is_sponsored: post_data["isSponsored"] || false,
      metadata: build_metadata(post_data)
    )

    if post.save
      Rails.logger.info "Saved post #{instagram_id} for scraping #{scraping.id}"
    else
      @errors << "Failed to save post #{instagram_id}: #{post.errors.full_messages.join(', ')}"
    end
  end

  def parse_timestamp(timestamp_str)
    return nil if timestamp_str.blank?
    Time.parse(timestamp_str)
  rescue ArgumentError
    nil
  end

  def build_metadata(post_data)
    {
      hashtags: post_data["hashtags"] || [],
      mentions: post_data["mentions"] || [],
      images: post_data["images"] || [],
      first_comment: post_data["firstComment"],
      latest_comments: post_data["latestComments"] || [],
      child_posts: post_data["childPosts"] || [],
      input_url: post_data["inputUrl"],
      product_type: post_data["productType"],
      music_info: post_data["musicInfo"]
    }.compact
  end
end