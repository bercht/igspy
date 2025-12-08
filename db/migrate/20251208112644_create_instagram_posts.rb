class CreateInstagramPosts < ActiveRecord::Migration[7.2]
  def change
    create_table :instagram_posts do |t|
      # Relacionamento
      t.references :scraping, null: false, foreign_key: true
      
      # IDs e identificadores únicos
      t.string :instagram_id, null: false  # campo 'id' do Apify
      t.string :short_code                 # campo 'shortCode'
      
      # Tipo e conteúdo básico
      t.string :post_type                  # 'Video', 'Image', 'Sidecar'
      t.text :caption                      # legenda do post
      t.string :url                        # URL do post no Instagram
      t.text :alt                          # texto alternativo da imagem
      
      # Métricas de engajamento
      t.integer :likes_count, default: 0
      t.integer :comments_count, default: 0
      t.integer :video_view_count          # views no vídeo
      t.integer :video_play_count          # reproduções do vídeo
      t.decimal :video_duration            # duração em segundos (pode ser decimal)
      t.datetime :posted_at                # campo 'timestamp' do Apify
      
      # Dimensões da mídia
      t.integer :dimensions_height
      t.integer :dimensions_width
      
      # URLs de mídia
      t.text :display_url                  # URL da imagem principal
      t.text :video_url                    # URL do vídeo (se for vídeo)
      t.text :audio_url                    # URL do áudio (se tiver)
      
      # Transcrição (para vídeos) - ADICIONADO PELO WORKFLOW
      t.text :transcription
      t.string :transcription_status, default: 'pending' # 'pending', 'processing', 'completed', 'failed'
      
      # Dados do proprietário/autor
      t.string :owner_username
      t.string :owner_full_name
      t.string :owner_id
      
      # Flags booleanas
      t.boolean :is_pinned, default: false
      t.boolean :is_comments_disabled, default: false
      t.boolean :is_sponsored, default: false
      
      # Metadata extra (arrays e objetos) como JSONB
      # Contém: hashtags, mentions, firstComment, latestComments, 
      #         images, childPosts, inputUrl, productType, musicInfo
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    # Índices para performance nas queries mais comuns
    add_index :instagram_posts, :instagram_id, unique: true
    # add_index :instagram_posts, :scraping_id
    add_index :instagram_posts, :posted_at
    add_index :instagram_posts, :likes_count
    add_index :instagram_posts, :video_view_count
    add_index :instagram_posts, :transcription_status
    add_index :instagram_posts, :post_type
    add_index :instagram_posts, :owner_username
    
    # Índice GIN para buscar dentro do JSONB (hashtags, etc)
    add_index :instagram_posts, :metadata, using: :gin
  end
end