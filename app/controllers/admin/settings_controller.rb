class Admin::SettingsController < Admin::BaseController
  before_action :set_user

  def edit
    # Renderiza a view de edição de configurações
  end

  def update
    # SEMPRE exige senha atual para qualquer alteração
    unless @user.valid_password?(params[:user][:current_password])
      @user.errors.add(:current_password, "está incorreta ou não foi informada")
      render :edit, status: :unprocessable_entity
      return
    end

    # Remove current_password dos params (não é um atributo do model)
    update_params = user_params

    # Se senha estiver vazia, remove dos params
    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      # Força re-autenticação se mudou a senha
      bypass_sign_in(@user) if params[:user][:password].present?
      redirect_to admin_settings_path, notice: "Configurações atualizadas com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(
      :email,
      :password,
      :password_confirmation,
      :manus_api_key,
      :anthropic_api_key,
      :preferred_chat_api
    )
  end
end