import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapse"
export default class extends Controller {
  static targets = ["content", "icon", "toggleText"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
    this.iconTarget.classList.toggle("rotate-180")
    
    if (this.contentTarget.classList.contains("hidden")) {
      this.toggleTextTarget.textContent = "Ver Análise Completa"
    } else {
      this.toggleTextTarget.textContent = "Ocultar Análise"
    }
  }
}
