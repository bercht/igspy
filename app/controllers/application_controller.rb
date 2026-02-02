class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Configurar layout por controller
  layout :layout_by_resource

  protected

  # Redirect após login - vai para o dashboard
  def after_sign_in_path_for(resource)
    admin_dashboard_path
  end

  # Redirect após logout - vai para a home pública
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  def configure_permitted_parameters
    # Permitir API keys e preferência de chat na atualização de conta (edit/update)
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :manus_api_key, 
      :anthropic_api_key,
      :preferred_chat_api
    ])
    
    # Se você quiser permitir na criação também (sign_up), descomente a linha abaixo:
    # devise_parameter_sanitizer.permit(:sign_up, keys: [:manus_api_key, :anthropic_api_key, :preferred_chat_api])
  end

  private

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end
end