class AddPerformanceIndexesToScrapings < ActiveRecord::Migration[7.2]
  def change
    # Índices compostos para queries por usuário (mais comum no dashboard)
    # user_id + created_at → para scrapings.recent (order: created_at DESC)
    add_index :scrapings, [:user_id, :created_at], 
              name: 'index_scrapings_on_user_and_created_at',
              order: { created_at: :desc }
    
    # user_id + status → para current_user.scrapings.where(status: X)
    add_index :scrapings, [:user_id, :status], 
              name: 'index_scrapings_on_user_and_status'
    
    # user_id + completed_at → para scrapings finalizados ordenados
    add_index :scrapings, [:user_id, :completed_at], 
              name: 'index_scrapings_on_user_and_completed_at',
              order: { completed_at: :desc },
              where: "completed_at IS NOT NULL"
    
    # Índice simples para status (queries globais ou admin)
    add_index :scrapings, :status, 
              name: 'index_scrapings_on_status'
    
    # Índice parcial para completed_at (apenas quando não é NULL)
    # Economiza espaço ignorando registros pendentes/em progresso
    add_index :scrapings, :completed_at, 
              name: 'index_scrapings_on_completed_at',
              order: { completed_at: :desc },
              where: "completed_at IS NOT NULL"
  end
end