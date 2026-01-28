# Adicionar estes métodos ao app/helpers/application_helper.rb
# Cole DENTRO do módulo ApplicationHelper, junto com os métodos existentes

  # ========== NOVOS HELPERS PARA STEPPER HORIZONTAL ==========

  # Define a ordem dos steps para comparação
  STEP_ORDER = %w[pending fetching processing completed].freeze

  def render_stepper_icon(step, current_status)
    step_index = STEP_ORDER.index(step) || 0
    current_index = STEP_ORDER.index(current_status) || 0

    # Determina o estado do step
    if step == 'failed' && current_status == 'failed'
      # Ícone de erro
      stepper_icon_error
    elsif current_status == 'failed' && step_index > current_index
      # Steps futuros quando falhou
      stepper_icon_pending
    elsif step_index < current_index || (step == 'completed' && current_status == 'completed')
      # Completado
      stepper_icon_completed
    elsif step_index == current_index
      # Em andamento
      stepper_icon_loading
    else
      # Pendente
      stepper_icon_pending
    end
  end

  def step_text_class(step, current_status)
    step_index = STEP_ORDER.index(step) || 0
    current_index = STEP_ORDER.index(current_status) || 0

    if current_status == 'failed'
      step_index <= current_index ? 'text-gray-900' : 'text-gray-400'
    elsif step_index < current_index || (step == 'completed' && current_status == 'completed')
      'text-green-600'
    elsif step_index == current_index
      'text-blue-600'
    else
      'text-gray-400'
    end
  end

  def connector_class(step, current_status)
    step_index = STEP_ORDER.index(step) || 0
    current_index = STEP_ORDER.index(current_status) || 0

    if current_status == 'failed'
      step_index <= current_index ? 'bg-gray-300' : 'bg-gray-200'
    elsif step_index <= current_index
      'bg-green-500'
    else
      'bg-gray-200'
    end
  end

  def status_message_display(scraping)
    return scraping.status_message if scraping.status_message.present?

    case scraping.status
    when 'pending'
      'Aguardando início...'
    when 'fetching'
      'Buscando postagens no Instagram...'
    when 'processing'
      'Processando dados coletados...'
    when 'completed'
      'Scraping concluído com sucesso!'
    when 'failed'
      'Ocorreu um erro no processamento.'
    else
      'Aguardando...'
    end
  end

  private

  def stepper_icon_completed
    content_tag(:div, class: "flex items-center justify-center w-10 h-10 rounded-full bg-green-100 border-2 border-green-500") do
      content_tag(:svg, class: "w-5 h-5 text-green-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M5 13l4 4L19 7")
      end
    end
  end

  def stepper_icon_loading
    content_tag(:div, class: "flex items-center justify-center w-10 h-10 rounded-full bg-blue-100 border-2 border-blue-500") do
      content_tag(:svg, class: "animate-spin w-5 h-5 text-blue-600", fill: "none", viewBox: "0 0 24 24") do
        concat tag.circle(class: "opacity-25", cx: "12", cy: "12", r: "10", stroke: "currentColor", stroke_width: "4")
        concat tag.path(class: "opacity-75", fill: "currentColor", d: "M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z")
      end
    end
  end

  def stepper_icon_pending
    content_tag(:div, class: "flex items-center justify-center w-10 h-10 rounded-full bg-gray-100 border-2 border-gray-300") do
      content_tag(:div, "", class: "w-3 h-3 rounded-full bg-gray-400")
    end
  end

  def stepper_icon_error
    content_tag(:div, class: "flex items-center justify-center w-10 h-10 rounded-full bg-red-100 border-2 border-red-500") do
      content_tag(:svg, class: "w-5 h-5 text-red-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M6 18L18 6M6 6l12 12")
      end
    end
  end
