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

      # Try fallback PDF generation with Prawn
      Rails.logger.info "Attempting fallback PDF generation with Prawn..."
      begin
        pdf_data = generate_prawn_pdf(@resume, template_name)

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
      rescue => fallback_error
        Rails.logger.error "Fallback PDF generation also failed: #{fallback_error.message}"
        render plain: "PDF generation failed due to browser configuration issue. Please try again or contact support.", status: :internal_server_error
      end

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

  def generate_prawn_pdf(resume, template_name)
    require "prawn"
    require "prawn/table"

    Prawn::Document.new do |pdf|
      # Set up basic styling
      pdf.font "Helvetica"
      pdf.font_size 10

      # Header
      pdf.font_size 24
      pdf.text "#{resume.user.first_name} #{resume.user.last_name}", style: :bold
      pdf.move_down 10

      # Contact info
      pdf.font_size 10
      contact_info = []
      contact_info << resume.user.location if resume.user.location.present?
      contact_info << resume.user.phone if resume.user.phone.present?
      contact_info << resume.user.email if resume.user.email.present?
      contact_info << "/in/#{resume.user.linked_in_url.split("/").last}" if resume.user.linked_in_url.present?
      contact_info << resume.user.github_url.split("//").last if resume.user.github_url.present?

      pdf.text contact_info.join(" | "), color: "666666"
      pdf.move_down 20

      # Summary
      if resume.summary&.body&.present?
        pdf.font_size 16
        pdf.text "Summary", style: :bold
        pdf.move_down 8
        pdf.font_size 10
        pdf.text resume.summary.body.to_plain_text
        pdf.move_down 15
      end

      # Skills
      if resume.skills.any?
        pdf.font_size 16
        pdf.text resume.skills_title.presence || "Skills", style: :bold
        pdf.move_down 8
        pdf.font_size 10
        skills_text = resume.skills.map(&:name).join(", ") + "."
        pdf.text skills_text
        pdf.move_down 15
      end

      # Experience
      if resume.experiences.any?
        pdf.font_size 16
        pdf.text "Experience", style: :bold
        pdf.move_down 8

        resume.experiences.each do |exp|
          pdf.font_size 12
          pdf.text "#{exp.title} @ #{exp.company_name}", style: :bold
          pdf.font_size 10
          pdf.text "#{exp.location} · #{exp.start_date&.strftime("%b %Y")} – #{exp.end_date&.strftime("%b %Y") || "Present"}", color: "666666"
          pdf.move_down 5

          if exp.responsibilities.any?
            exp.responsibilities.each do |resp|
              pdf.text "• #{resp.content}"
              pdf.move_down 2
            end
          end
          pdf.move_down 10
        end
      end

      # Education
      if resume.educations.any?
        pdf.font_size 16
        pdf.text "Education", style: :bold
        pdf.move_down 8

        resume.educations.each do |edu|
          pdf.font_size 12
          pdf.text edu.school, style: :bold
          pdf.font_size 10
          pdf.text "#{edu.field_of_study} · #{edu.start_date&.year} – #{edu.end_date&.year || "Present"}", color: "666666"
          pdf.move_down 10
        end
      end

      # Projects
      if resume.projects.any?
        pdf.font_size 16
        pdf.text "Projects", style: :bold
        pdf.move_down 8

        resume.projects.each do |proj|
          pdf.font_size 12
          pdf.text proj.title, style: :bold
          if proj.url.present?
            pdf.font_size 10
            pdf.text proj.url, color: "0066cc"
          end
          if proj.description&.body&.present?
            pdf.move_down 5
            pdf.text proj.description.body.to_plain_text
          end
          pdf.move_down 10
        end
      end
    end.render
  end

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
