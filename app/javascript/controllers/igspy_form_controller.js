import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "submitButton", "loadingText", "profileUrl", "resultsLimit"]

  connect() {
    console.log("Igspy form controller connected")
  }

  submit(event) {
    // Validar URL do perfil
    const profileUrlValue = this.profileUrlTarget.value.trim()
    
    if (!profileUrlValue) {
      event.preventDefault()
      alert("Por favor, preencha a URL do perfil Instagram")
      return
    }

    // Validar se contém instagram.com
    if (!profileUrlValue.includes("instagram.com")) {
      event.preventDefault()
      alert("A URL deve ser um perfil do Instagram (instagram.com)")
      return
    }

    // Validar número de resultados
    const resultsLimit = parseInt(this.resultsLimitTarget.value)
    if (resultsLimit < 1 || resultsLimit > 100) {
      event.preventDefault()
      alert("O número de postagens deve estar entre 1 e 100")
      return
    }

    // Mostrar loading state
    this.submitButtonTarget.disabled = true
    this.loadingTextTarget.classList.remove("hidden")
  }
}