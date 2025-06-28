// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import "../assets/stylesheets/application.tailwind.css";

import "trix"
import "@rails/actiontext"

document.addEventListener("turbo:load", () => {
  let googleAnalyticsMeta = document.querySelector("meta[name='google-analytics']");

  if (googleAnalyticsMeta) {
    const googleId = googleAnalyticsMeta.getAttribute('content');

    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());

    gtag('config', googleId);
  }
});
