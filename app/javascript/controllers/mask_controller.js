// app/javascript/controllers/mask_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { pattern: String }

  connect() {
    this.element.addEventListener('input', this.format.bind(this))
  }

  format(event) {
    const pattern = this.patternValue
    let value = event.target.value.replace(/\D/g, '')
    
    if (pattern === "000.000.000-00") {
      // Máscara de CPF
      value = value.substring(0, 11)
      value = value.replace(/(\d{3})(\d)/, '$1.$2')
      value = value.replace(/(\d{3})(\d)/, '$1.$2')
      value = value.replace(/(\d{3})(\d{1,2})$/, '$1-$2')
    } else if (pattern === "(00) 00000-0000") {
      // Máscara de telefone
      value = value.substring(0, 11)
      value = value.replace(/(\d{2})(\d)/, '($1) $2')
      value = value.replace(/(\d{5})(\d)/, '$1-$2')
    }
    
    event.target.value = value
  }
}