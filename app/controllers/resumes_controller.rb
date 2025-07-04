class ResumesController < ApplicationController
  before_action :authenticate_user!, except: [ :show, :public, :public_pdf, :public_pdf_download, :public_pdf_modern, :public_pdf_classic, :pdf_health_check, :test_pdf, :pdf_diagnostic ]
  before_action :set_resume_public, only: [ :public, :public_pdf, :public_pdf_download, :public_pdf_modern, :public_pdf_classic ]
  before_action :set_resume, except: [ :public, :public_pdf, :public_pdf_download, :public_pdf_modern, :public_pdf_classic, :pdf_health_check, :test_pdf, :pdf_diagnostic ]

  def show; end

  def edit; end

  def update
    if @resume.update(resume_params)
      if @resume.summary.present? and @resume.title.present? and @resume.skills.any? and @resume.experiences.any? and @resume.educations.any?
        redirect_to resume_path, notice: "Resume updated!"
      else
        redirect_to edit_resume_path, notice: "Resume updated!"
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def public
  end

  def public_pdf
    template_name = case @resume.pdf_template
    when "classic"
      "classic"
    else
      "modern"
    end

    # Render HTML first to catch any template errors
    html = render_to_string(
      template: "resumes/public_pdf_#{template_name}",
      layout: "pdf",
      formats: [ :html ],
      locals: { resume: @resume }
    )

    begin
      # Use Grover with global configuration
      grover = Grover.new(html)

      # Set a timeout for the PDF generation
      Timeout.timeout(30) do
        pdf_data = grover.to_pdf

        # Determine disposition based on query parameter or default to inline
        # Check multiple ways the download parameter might be passed
        is_download = params[:download] == "true" ||
                     params[:download] == true ||
                     request.query_string.include?("download=true") ||
                     request.referer&.include?("download=true")

        disposition = is_download ? "attachment" : "inline"

        # Set proper headers for PDF display
        response.headers["Content-Type"] = "application/pdf"
        response.headers["Content-Disposition"] = "#{disposition}; filename=\"#{@resume.user_first_name}_resume.pdf\""
        response.headers["Content-Length"] = pdf_data.length.to_s
        response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"

        # Additional headers to force download
        if disposition == "attachment"
          response.headers["X-Content-Type-Options"] = "nosniff"
          response.headers["Content-Transfer-Encoding"] = "binary"
        end

        # Send the PDF data
        send_data pdf_data,
                  filename: "#{@resume.user_first_name}_resume.pdf",
                  type: "application/pdf",
                  disposition: disposition
      end

    rescue Timeout::Error => e
      Rails.logger.error "PDF generation timed out after 30 seconds"
      Rails.logger.error "Timeout error: #{e.message}"

      # Fallback: return HTML instead of PDF
      render template: "resumes/public_pdf_#{template_name}", layout: "pdf", locals: { resume: @resume }, formats: [ :html ]

    rescue Grover::JavaScript::UnknownError => e
      Rails.logger.error "Grover JavaScript error: #{e.message}"
      Rails.logger.error "Grover error details: #{e.inspect}"
      Rails.logger.error "Grover error backtrace: #{e.backtrace.first(5).join("\n")}"

      # Fallback: return HTML instead of PDF
      render template: "resumes/public_pdf_#{template_name}", layout: "pdf", locals: { resume: @resume }, formats: [ :html ]

    rescue => e
      Rails.logger.error "PDF generation error: #{e.message}"
      Rails.logger.error "Error class: #{e.class}"
      Rails.logger.error "Error backtrace: #{e.backtrace.first(5).join("\n")}"

      # Fallback: return HTML instead of PDF
      render template: "resumes/public_pdf_#{template_name}", layout: "pdf", locals: { resume: @resume }, formats: [ :html ]
    end
  end

  def public_pdf_download
    template_name = case @resume.pdf_template
    when "classic"
      "classic"
    else
      "modern"
    end

    # Render HTML first to catch any template errors
    html = render_to_string(
      template: "resumes/public_pdf_#{template_name}",
      layout: "pdf",
      formats: [ :html ],
      locals: { resume: @resume }
    )

    begin
      # Use Grover with global configuration
      grover = Grover.new(html)

      # Set a timeout for the PDF generation
      Timeout.timeout(30) do
        pdf_data = grover.to_pdf

        # Set proper headers for PDF download
        response.headers["Content-Type"] = "application/pdf"
        response.headers["Content-Disposition"] = "attachment; filename=\"#{@resume.user_first_name}_resume.pdf\""
        response.headers["Content-Length"] = pdf_data.length.to_s
        response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Content-Transfer-Encoding"] = "binary"

        # Send the PDF data
        send_data pdf_data,
                  filename: "#{@resume.user_first_name}_resume.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end

    rescue Timeout::Error => e
      Rails.logger.error "PDF generation timed out after 30 seconds"
      Rails.logger.error "Timeout error: #{e.message}"
      Rails.logger.error "Resume ID: #{@resume.id}, Slug: #{@resume.slug}"
      render plain: "PDF generation timed out. Please try again.", status: :request_timeout

    rescue Grover::JavaScript::UnknownError => e
      Rails.logger.error "Grover JavaScript error: #{e.message}"
      Rails.logger.error "Grover error details: #{e.inspect}"
      Rails.logger.error "Resume ID: #{@resume.id}, Slug: #{@resume.slug}"
      Rails.logger.error "Grover executable path: #{Grover.configuration.options[:executable_path]}"
      Rails.logger.error "Template: public_pdf_#{template_name}"
      Rails.logger.error "HTML length: #{html.length}"

      # Try to get more details about the error
      if e.message.include?("[object Object]")
        Rails.logger.error "This appears to be a Chromium/Chrome executable issue"
        Rails.logger.error "Check if Chromium is properly installed and accessible"
      end

      # Log the first 500 characters of the HTML for debugging
      Rails.logger.error "HTML preview: #{html[0..500]}..."

      render plain: "PDF generation failed due to browser configuration issue. Please try again or contact support.", status: :internal_server_error

    rescue => e
      Rails.logger.error "PDF generation error: #{e.message}"
      Rails.logger.error "Error class: #{e.class}"
      Rails.logger.error "Resume ID: #{@resume.id}, Slug: #{@resume.slug}"
      Rails.logger.error "Error backtrace: #{e.backtrace.first(5).join("\n")}"
      render plain: "PDF generation failed. Please try again later.", status: :internal_server_error
    end
  end

  def pdf_health_check
    # Simple health check for PDF generation
    begin
      html = "<html><body><h1>PDF Test</h1><p>Generated at: #{Time.current}</p></body></html>"
      grover = Grover.new(html)
      pdf_data = grover.to_pdf

      render json: {
        status: "healthy",
        message: "PDF generation is working",
        pdf_size: pdf_data.length,
        executable_path: Grover.configuration.options[:executable_path],
        timestamp: Time.current
      }
    rescue => e
      render json: {
        status: "unhealthy",
        message: "PDF generation failed",
        error: e.message,
        error_class: e.class.name,
        executable_path: Grover.configuration.options[:executable_path],
        timestamp: Time.current
      }, status: :internal_server_error
    end
  end

  def test_pdf
    # Simple test endpoint to verify PDF generation
    begin
      # First, let's check what Chromium paths are available
      chromium_paths = [
        "/usr/bin/chromium",
        "/usr/bin/chromium-browser",
        "/usr/bin/google-chrome",
        "/usr/bin/google-chrome-stable"
      ]

      available_paths = chromium_paths.select { |path| File.exist?(path) }

      # Check current Grover configuration
      grover_executable = Grover.configuration.options[:executable_path]

      html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>Test PDF</title>
          <style>
            body { font-family: Arial, sans-serif; font-size: 12px; }
          </style>
        </head>
        <body>
          <h1>Test PDF Generation</h1>
          <p>This is a test PDF to verify that Grover is working correctly.</p>
          <p>Generated at: #{Time.current}</p>
          <p>Grover executable: #{grover_executable}</p>
          <p>Available Chromium paths: #{available_paths.join(', ')}</p>
        </body>
        </html>
      HTML

      grover = Grover.new(html)
      pdf_data = grover.to_pdf

      send_data pdf_data,
                filename: "test.pdf",
                type: "application/pdf",
                disposition: "attachment"
    rescue => e
      # Provide detailed error information
      error_info = <<~ERROR
        PDF generation failed!

        Error: #{e.message}
        Error class: #{e.class}

        Grover executable path: #{Grover.configuration.options[:executable_path]}

        Available Chromium paths:
        #{chromium_paths.map { |p| "  #{p}: #{File.exist?(p) ? 'EXISTS' : 'NOT FOUND'}" }.join("\n")}

        Environment:
        - Rails env: #{Rails.env}
        - Ruby version: #{RUBY_VERSION}

        Full error details:
        #{e.backtrace.first(5).join("\n")}
      ERROR

      render plain: error_info, status: :internal_server_error
    end
  end

  def pdf_diagnostic
    # Simple diagnostic endpoint that doesn't generate PDFs
    chromium_paths = [
      "/usr/bin/chromium",
      "/usr/bin/chromium-browser",
      "/usr/bin/google-chrome",
      "/usr/bin/google-chrome-stable"
    ]

    available_paths = chromium_paths.select { |path| File.exist?(path) }
    grover_executable = Grover.configuration.options[:executable_path]

    # Try to find Chromium using which command
    system_chromium = nil
    begin
      require "open3"
      stdout, stderr, status = Open3.capture3("which chromium")
      system_chromium = stdout.strip if status.success?
    rescue => e
      system_chromium = "Error: #{e.message}"
    end

    # Try to run the verification script if it exists
    verification_output = nil
    if File.exist?("/rails/bin/verify-chromium")
      begin
        verification_output = `bash /rails/bin/verify-chromium 2>&1`
      rescue => e
        verification_output = "Error running verification: #{e.message}"
      end
    end

    diagnostic_info = {
      status: "diagnostic",
      timestamp: Time.current,
      environment: {
        rails_env: Rails.env,
        ruby_version: RUBY_VERSION
      },
      grover_config: {
        executable_path: grover_executable,
        format: Grover.configuration.options[:format],
        args_count: Grover.configuration.options[:args].length
      },
      chromium_paths: {
        available: available_paths,
        checked: chromium_paths,
        system_chromium: system_chromium
      },
      file_permissions: available_paths.map do |path|
        {
          path: path,
          exists: File.exist?(path),
          executable: File.executable?(path),
          size: File.exist?(path) ? File.size(path) : nil
        }
      end,
      verification_script: {
        exists: File.exist?("/rails/bin/verify-chromium"),
        output: verification_output
      }
    }

    render json: diagnostic_info
  end

  private

  def set_resume
    @resume = current_user.resume
  end

  def set_resume_public
    @resume = Resume.find_by(slug: params[:slug])
    unless @resume
      render plain: "Resume not found. The resume you're looking for doesn't exist or may have been removed.", status: :not_found
      nil
    end
  end

  def resume_params
    params.require(:resume).permit(
      :skills_title, :summary, :title, :pdf_template,
      skills_attributes: [ :id, :name, :_destroy ],
      educations_attributes: [ :id, :school, :location, :field_of_study, :start_date, :end_date, :_destroy ],
      projects_attributes: [ :id, :title, :description, :url, :_destroy ]
    )
  end
end
