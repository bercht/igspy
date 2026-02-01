import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content", "icon"]

  toggle(event) {
    const button = event.currentTarget
    const index = this.buttonTargets.indexOf(button)
    const content = this.contentTargets[index]
    const icon = this.iconTargets[index]

    // Toggle content
    content.classList.toggle('hidden')
    
    // Rotate icon
    icon.classList.toggle('rotate-180')
  }
}
