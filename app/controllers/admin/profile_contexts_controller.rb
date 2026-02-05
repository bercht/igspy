# app/controllers/admin/profile_context_controller.rb
class Admin::ProfileContextsController < Admin::BaseController
  def show
    @context = current_user.user_profile_context || current_user.build_user_profile_context
    
    # Se não existe contexto, disparar análise
    if @context.new_record?
      ProfileContextAnalyzerService.call(current_user)
      @context.reload
    end
  end
  
  def update
    @context = current_user.user_profile_context
    
    if @context.update(context_params.merge(manually_edited: true))
      redirect_to admin_profile_context_path, notice: 'Contexto atualizado com sucesso!'
    else
      render :show, status: :unprocessable_entity
    end
  end
  
  def reanalyze
    result = ProfileContextAnalyzerService.call(current_user)
    
    if result[:success]
      redirect_to admin_profile_context_path, notice: 'Reanálise iniciada! Aguarde alguns minutos.'
    else
      redirect_to admin_profile_context_path, alert: "Erro ao iniciar reanálise: #{result[:error]}"
    end
  end
  
  private
  
  def context_params
    params.require(:user_profile_context).permit(
      :detected_niche,
      :detected_audience,
      :communication_tone,
      :user_corrections,
      frequent_themes: []
    )
  end
end