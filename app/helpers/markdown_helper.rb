# app/helpers/markdown_helper.rb
module MarkdownHelper
  def render_markdown(text)
    return "" if text.blank?
    
    # Configurar Redcarpet com extensões
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      link_attributes: { target: '_blank', rel: 'noopener noreferrer' }
    )
    
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      highlight: true,
      footnotes: true
    )
    
    # Renderizar e sanitizar
    html = markdown.render(text)
    sanitize(html, tags: %w[
      h1 h2 h3 h4 h5 h6 p br strong em del sup sub
      ul ol li blockquote pre code a table thead tbody tr th td
    ], attributes: %w[href target rel class])
  end
end
