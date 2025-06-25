# Configure Grover for PDF generation
# This initializer sets up Grover with production-friendly options

Rails.application.config.after_initialize do
  # Configure Grover with production-friendly options
  Grover.configure do |config|
    # Set production-friendly Chrome arguments
    config.options = {
      format: "A4",
      margin: {
        top: "0.5in",
        bottom: "0.5in",
        left: "0.5in",
        right: "0.5in"
      },
      prefer_css_page_size: true,
      emulate_media: "screen",
      # Production-specific Chrome arguments
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--disable-accelerated-2d-canvas",
        "--no-first-run",
        "--no-zygote",
        "--disable-gpu",
        "--disable-web-security",
        "--disable-features=VizDisplayCompositor"
      ]
    }
  end

  Rails.logger.info "Grover configured with production-friendly options"
end
