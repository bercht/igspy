class AddTranscriptionFieldsToInstagramPosts < ActiveRecord::Migration[7.2]
  def change
    # Adicionar apenas se não existir
    unless column_exists?(:instagram_posts, :transcription_status)
      add_column :instagram_posts, :transcription_status, :string, default: 'pending'
    end
    
    unless column_exists?(:instagram_posts, :assembly_transcript_id)
      add_column :instagram_posts, :assembly_transcript_id, :string
    end
    
    # Índice composto para queries de verificação
    unless index_exists?(:instagram_posts, [:scraping_id, :transcription_status], 
                        name: 'idx_posts_scraping_transcription')
      add_index :instagram_posts, [:scraping_id, :transcription_status], 
                name: 'idx_posts_scraping_transcription',
                where: "video_url IS NOT NULL"
    end
    
    # Índice para busca por transcript_id (callbacks)
    unless index_exists?(:instagram_posts, :assembly_transcript_id,
                        name: 'idx_posts_assembly_transcript')
      add_index :instagram_posts, :assembly_transcript_id,
                name: 'idx_posts_assembly_transcript',
                where: "assembly_transcript_id IS NOT NULL"
    end
    
    # Atualizar posts existentes (apenas se coluna foi recém-criada)
    reversible do |dir|
      dir.up do
        # Posts COM transcrição → completed
        execute <<-SQL
          UPDATE instagram_posts 
          SET transcription_status = 'completed'
          WHERE transcription_status = 'pending'
            AND transcription IS NOT NULL 
            AND transcription != '';
        SQL
        
        # Posts SEM vídeo → not_applicable
        execute <<-SQL
          UPDATE instagram_posts 
          SET transcription_status = 'not_applicable'
          WHERE transcription_status = 'pending'
            AND video_url IS NULL;
        SQL
      end
    end
  end
end