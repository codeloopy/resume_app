# Configure Grover for PDF generation
# This initializer sets up Grover with production-friendly options

Rails.application.config.after_initialize do
  # Configure Grover with production-friendly options
  Grover.configure do |config|
    # Set production-friendly Chrome arguments
    config.options = {
      format: "Letter",
      margin: {
        top: "0.25in",
        bottom: "0.25in",
        left: "0.25in",
        right: "0.25in"
      },
      prefer_css_page_size: true,
      emulate_media: "screen",
      # Production-specific Chrome arguments (--no-sandbox must be first when running as root)
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--disable-accelerated-2d-canvas",
        "--no-first-run",
        "--no-zygote",
        "--disable-gpu",
        "--disable-web-security",
        "--disable-features=VizDisplayCompositor",
        "--disable-background-timer-throttling",
        "--disable-backgrounding-occluded-windows",
        "--disable-renderer-backgrounding",
        "--disable-field-trial-config",
        "--disable-ipc-flooding-protection"
      ]
    }

    # Only set executable_path in production
    if Rails.env.production?
      config.options[:executable_path] = "/usr/bin/chromium"
    end
  end

  Rails.logger.info "Grover configured with production-friendly options"
end
