module ApplicationHelper
  def status_badge_class(status)
    case status
    when "pending"
      "bg-gray-100 text-gray-800"
    when "fetching"
      "bg-blue-100 text-blue-800"
    when "processing"
      "bg-yellow-100 text-yellow-800"
    when "completed"
      "bg-green-100 text-green-800"
    when "failed"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def progress_percentage(status)
    case status
    when "pending"
      10
    when "fetching"
      40
    when "processing"
      70
    when "completed"
      100
    else
      0
    end
  end

  def render_timeline_icon(scraping, step)
    current_status = scraping.status
    
    # Determina se o step já foi completado
    completed = case step
    when "pending"
      true
    when "fetching"
      ["fetching", "processing", "completed"].include?(current_status)
    when "processing"
      ["processing", "completed"].include?(current_status)
    when "completed"
      current_status == "completed"
    when "failed"
      current_status == "failed"
    else
      false
    end

    if step == "failed" && current_status == "failed"
      # Ícone de erro (vermelho)
      content_tag(:div, class: "flex items-center justify-center w-8 h-8 rounded-full bg-red-100") do
        content_tag(:svg, class: "w-5 h-5 text-red-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M6 18L18 6M6 6l12 12")
        end
      end
    elsif completed
      # Ícone de check (verde)
      content_tag(:div, class: "flex items-center justify-center w-8 h-8 rounded-full bg-green-100") do
        content_tag(:svg, class: "w-5 h-5 text-green-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          tag.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M5 13l4 4L19 7")
        end
      end
    elsif current_status == step
      # Ícone de loading (azul animado)
      content_tag(:div, class: "flex items-center justify-center w-8 h-8 rounded-full bg-blue-100") do
        content_tag(:svg, class: "animate-spin w-5 h-5 text-blue-600", fill: "none", viewBox: "0 0 24 24") do
          concat tag.circle(class: "opacity-25", cx: "12", cy: "12", r: "10", stroke: "currentColor", stroke_width: "4")
          concat tag.path(class: "opacity-75", fill: "currentColor", d: "M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z")
        end
      end
    else
      # Ícone pendente (cinza)
      content_tag(:div, class: "flex items-center justify-center w-8 h-8 rounded-full bg-gray-100") do
        content_tag(:div, "", class: "w-3 h-3 rounded-full bg-gray-400")
      end
    end
  end
end