// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import "../assets/stylesheets/application.tailwind.css";

import "trix"
import "@rails/actiontext"

document.addEventListener("turbo:load", () => {
  // Turbo load event handler
});
