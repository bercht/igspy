import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "mobileMenu", "menuIcon", "closeIcon"]

  connect() {
    window.addEventListener('scroll', this.handleScroll.bind(this))
  }

  disconnect() {
    window.removeEventListener('scroll', this.handleScroll.bind(this))
  }

  handleScroll() {
    if (window.scrollY > 20) {
      this.containerTarget.classList.add('glass', 'py-3')
      this.containerTarget.classList.remove('py-5')
    } else {
      this.containerTarget.classList.remove('glass', 'py-3')
      this.containerTarget.classList.add('py-5')
    }
  }

  toggleMenu() {
    this.mobileMenuTarget.classList.toggle('hidden')
    this.menuIconTarget.classList.toggle('hidden')
    this.closeIconTarget.classList.toggle('hidden')
  }
}
