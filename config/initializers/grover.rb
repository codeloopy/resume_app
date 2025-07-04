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
        "--disable-features=VizDisplayCompositor",
        "--disable-background-timer-throttling",
        "--disable-backgrounding-occluded-windows",
        "--disable-renderer-backgrounding",
        "--disable-field-trial-config",
        "--disable-ipc-flooding-protection",
        "--disable-extensions",
        "--disable-plugins",
        "--disable-images",
        "--disable-javascript",
        "--disable-default-apps",
        "--disable-sync",
        "--disable-translate",
        "--hide-scrollbars",
        "--mute-audio",
        "--no-default-browser-check",
        "--disable-component-extensions-with-background-pages",
        "--disable-background-networking",
        "--disable-sync-preferences",
        "--disable-client-side-phishing-detection",
        "--disable-hang-monitor",
        "--disable-prompt-on-repost",
        "--disable-domain-reliability",
        "--disable-features=TranslateUI",
        "--disable-background-timer-throttling",
        "--disable-backgrounding-occluded-windows",
        "--disable-renderer-backgrounding",
        "--disable-features=VizDisplayCompositor",
        "--disable-ipc-flooding-protection",
        "--disable-extensions",
        "--disable-plugins",
        "--disable-images",
        "--disable-javascript",
        "--disable-default-apps",
        "--disable-sync",
        "--disable-translate",
        "--hide-scrollbars",
        "--mute-audio",
        "--no-default-browser-check",
        "--disable-component-extensions-with-background-pages",
        "--disable-background-networking",
        "--disable-sync-preferences",
        "--disable-client-side-phishing-detection",
        "--disable-hang-monitor",
        "--disable-prompt-on-repost",
        "--disable-domain-reliability",
        "--disable-features=TranslateUI"
      ]
    }

    # Set executable path for production
    if Rails.env.production?
      # Try to find Chromium in common locations
      possible_paths = [
        "/usr/bin/chromium",
        "/usr/bin/chromium-browser",
        "/usr/bin/google-chrome",
        "/usr/bin/google-chrome-stable",
        "/snap/bin/chromium",
        "/opt/google/chrome/chrome"
      ]

      # Check which paths exist
      existing_paths = possible_paths.select { |path| File.exist?(path) }

      if existing_paths.any?
        # Use the first existing path
        config.options[:executable_path] = existing_paths.first
        Rails.logger.info "Grover configured with Chromium at: #{existing_paths.first}"
        Rails.logger.info "All available paths: #{existing_paths.join(', ')}"
      else
        # Try using which command as fallback
        begin
          require "open3"
          stdout, stderr, status = Open3.capture3("which chromium")
          if status.success?
            config.options[:executable_path] = stdout.strip
            Rails.logger.info "Found Chromium using 'which': #{stdout.strip}"
          else
            # Try google-chrome
            stdout, stderr, status = Open3.capture3("which google-chrome")
            if status.success?
              config.options[:executable_path] = stdout.strip
              Rails.logger.info "Found Google Chrome using 'which': #{stdout.strip}"
            else
              Rails.logger.error "No Chromium/Chrome executable found. PDF generation will likely fail."
              Rails.logger.error "Checked paths: #{possible_paths.join(', ')}"

              # Try to run the verification script if it exists
              if File.exist?("/rails/bin/verify-chromium")
                Rails.logger.info "Running Chromium verification script..."
                verification_output = `bash /rails/bin/verify-chromium 2>&1`
                Rails.logger.info "Verification output: #{verification_output}"
              end
            end
          end
        rescue => e
          Rails.logger.error "Error finding Chromium: #{e.message}"
        end
      end

      # Log the final configuration
      Rails.logger.info "Final Grover configuration:"
      Rails.logger.info "  Executable path: #{config.options[:executable_path]}"
      Rails.logger.info "  Format: #{config.options[:format]}"
      Rails.logger.info "  Args count: #{config.options[:args].length}"
    end
  end

  Rails.logger.info "Grover configured with production-friendly options"
end
