// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import "../assets/stylesheets/application.tailwind.css";

import "trix"
import "@rails/actiontext"

document.addEventListener("turbo:load", () => {
  let googleId = document.querySelector("meta[name='google-site-verification']");

  if (googleId) {
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());

    gtag('config', googleId);
  }
});
