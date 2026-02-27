class ResumesController < ApplicationController
  before_action :authenticate_user!, except: [ :show, :public, :public_pdf, :public_pdf_download, :public_pdf_modern, :public_pdf_classic, :pdf_health_check, :test_pdf, :pdf_diagnostic ]
  before_action :set_resume_public, only: [ :public, :public_pdf, :public_pdf_download, :public_pdf_modern, :public_pdf_classic ]
  before_action :set_resume, except: [ :index, :create, :destroy, :switch, :public, :public_pdf, :public_pdf_download, :public_pdf_modern, :public_pdf_classic, :pdf_health_check, :test_pdf, :pdf_diagnostic ]
  before_action :set_resume_for_destroy, only: [ :destroy ]

  def index
    @resumes = current_user.resumes.order(updated_at: :desc)
    # Free users with 1 resume: redirect to edit (no need for list view)
    if @resumes.one? && !current_user.premium?
      redirect_to edit_resume_path and return
    end
    # Users with 0 resumes stay on index to see "Start Resume" button
  end

  def create
    # Allow create when: premium (multi-resume) OR has no resumes (everyone gets at least one)
    unless current_user.premium? || current_user.resume_count.zero?
      redirect_to pricing_path, alert: "Upgrade to Growth or Pro to create multiple resumes."
      return
    end
    if current_user.at_resume_limit?
      redirect_to resumes_path, alert: "You've reached your resume limit."
      return
    end

    new_resume = current_user.create_resume
    redirect_to edit_resume_path, notice: "New resume created! Start editing."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to resumes_path, alert: "Could not create resume: #{e.message}"
  end

  def switch
    resume = current_user.resumes.find_by(slug: params[:slug])
    unless resume
      redirect_to resumes_path, alert: "Resume not found."
      return
    end
    current_user.switch_resume!(resume)
    redirect_to edit_resume_path, notice: "Switched to #{resume.title.presence || 'Untitled'} resume."
  end

  def show
    if current_user
      # User is authenticated, show their own resume
      @resume = current_user.resume
      redirect_to resumes_path and return if @resume.nil?
    else
      # If !current_user, redirect to public view if slug is provided
      if params[:slug]
        @resume = Resume.find_by(slug: params[:slug])
        if @resume
          render :public
        else
          flash[:alert] = "😭 The resume you're looking for doesn't exist or may have been removed."
          redirect_to root_path
        end
      else
        flash[:notice] = "Please sign in to view your resume."
        # No slug provided and no user, redirect to login
        redirect_to new_user_session_path, alert: "Please sign in to view your resume."
      end
    end
  end

  def edit
    unless @resume
      redirect_to new_user_session_path, alert: "Please sign in to edit your resume."
    end
  end

  def update
    unless @resume
      redirect_to new_user_session_path, alert: "Please sign in to update your resume."
      return
    end

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

  def destroy
    unless @resume
      redirect_to new_user_session_path, alert: "Please sign in to delete your resume."
      return
    end

    if @resume.destroy
      redirect_to resumes_path, notice: "Resume deleted."
    else
      redirect_to((params[:slug] ? resumes_path : resume_path), alert: "Failed to delete resume. Please try again.")
    end
  end

  def public
    track_guest_public_resume_view
  end

  def public_pdf
    track_guest_pdf_view
    template_name = resolve_pdf_template(@resume.pdf_template)

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
    # Block guest users from downloading PDFs
    if current_user&.guest?
      flash[:alert] = "Please create an account to download your resume as a PDF."
      redirect_to resume_path and return
    end

    template_name = resolve_pdf_template(@resume.pdf_template)

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

  def test_prawn_pdf
    # Test endpoint specifically for Prawn PDF generation with UTF-8 support
    begin
      # Create a test resume with some Unicode content
      user = User.first || User.create!(
        email: "test@example.com",
        password: "password123",
        first_name: "Test",
        last_name: "User"
      )

      resume = user.resume || Resume.create!(
        user: user,
        title: "Test Resume",
        pdf_template: "modern"
      )

      # Test with content that might have Unicode characters
      test_content = "Test content with special characters: é, ñ, ü, 🚀, 📧, etc."

      # Generate PDF using Prawn
      pdf_data = generate_prawn_pdf(resume, "modern")

      send_data pdf_data,
                filename: "test_prawn.pdf",
                type: "application/pdf",
                disposition: "attachment"

    rescue => e
      error_info = <<~ERROR
        Prawn PDF generation failed!

        Error: #{e.message}
        Error class: #{e.class}

        Environment:
        - Rails env: #{Rails.env}
        - Ruby version: #{RUBY_VERSION}

        Font availability:
        - Noto Sans: #{File.exist?("/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf") ? 'Available' : 'Not found'}
        - Noto Serif: #{File.exist?("/usr/share/fonts/truetype/noto/NotoSerif-Regular.ttf") ? 'Available' : 'Not found'}
        - Liberation Sans: #{File.exist?("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf") ? 'Available' : 'Not found'}

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

  def resolve_pdf_template(template)
    # Resume#pdf_template already enforces Pro for premium; use raw value for rendering
    raw = template.presence || "modern"
    Resume::ALL_TEMPLATES.include?(raw) ? raw : "modern"
  end

  def generate_prawn_pdf(resume, template_name)
    require "prawn"
    require "prawn/table"

    # Map premium templates to Prawn styles (Prawn has modern/classic only)
    prawn_style = case template_name
    when "classic", "executive" then "classic"
    else "modern"
    end

    template_data = get_template_data(resume, template_name)
    generate_prawn_from_template(resume, template_data, prawn_style)
  end

  def get_template_data(resume, template_name)
    # Unified data structure for both HTML and PDF generation
    {
      header: {
        name: sanitize_text("#{resume.user.first_name} #{resume.user.last_name}"),
        title: sanitize_text(resume.title),
        contact_info: build_contact_info(resume.user)
      },
      sections: {
        summary: resume.summary&.body&.present? ? {
          title: %w[classic executive].include?(template_name) ? "SUMMARY" : "Summary",
          content: sanitize_text(resume.summary.body.to_plain_text)
        } : nil,
        skills: resume.skills.any? ? {
          title: (resume.skills_title.presence || "Skills").then { |t| %w[classic executive].include?(template_name) ? t.upcase : t },
          content: resume.skills.map { |skill| sanitize_text(skill.name) },
          separator: %w[classic executive].include?(template_name) ? " | " : ", "
        } : nil,
        experience: resume.experiences.any? ? {
          title: %w[classic executive].include?(template_name) ? "EXPERIENCE" : "Experience",
          items: resume.experiences.map do |exp|
            {
              company: sanitize_text(exp.company_name),
              location: sanitize_text(exp.location),
              title: sanitize_text(exp.title),
              start_date: exp.start_date,
              end_date: exp.end_date,
              responsibilities: exp.responsibilities.map { |resp| sanitize_text(resp.content) }
            }
          end
        } : nil,
        education: resume.educations.any? ? {
          title: %w[classic executive].include?(template_name) ? "EDUCATION" : "Education",
          items: resume.educations.map do |edu|
            {
              school: sanitize_text(edu.school),
              field: sanitize_text(edu.field_of_study),
              start_date: edu.start_date,
              end_date: edu.end_date
            }
          end
        } : nil,
        projects: resume.projects.any? ? {
          title: %w[classic executive].include?(template_name) ? "PROJECTS" : "Projects",
          items: resume.projects.map do |proj|
            {
              title: sanitize_text(proj.title),
              url: proj.url,
              description: sanitize_text(proj.description&.body&.to_plain_text)
            }
          end
        } : nil
      },
      styling: {
        font_family: %w[classic executive].include?(template_name) ? "Noto Serif" : "Noto Sans",
        margins: {
          left: 18,
          right: 18,
          top: 32,
          bottom: 36
        }
      }
    }
  end

  def build_contact_info(user)
    contact_info = []
    contact_info << sanitize_text(user.location) if user.location.present?
    contact_info << sanitize_text(user.phone) if user.phone.present?
    contact_info << sanitize_text(user.email) if user.email.present?
    contact_info << "/in/#{user.linked_in_url.split("/").last}" if user.linked_in_url.present?
    contact_info << user.github_url.split("//").last if user.github_url.present?
    contact_info
  end

  def sanitize_text(text)
    return text unless text.is_a?(String)

    # Remove or replace problematic characters for PDF generation
    # Keep common punctuation and symbols, but remove emojis and other problematic Unicode
    text.gsub(/[\u{1F600}-\u{1F64F}]/, "") # Remove emoji faces
         .gsub(/[\u{1F300}-\u{1F5FF}]/, "") # Remove emoji symbols
         .gsub(/[\u{1F680}-\u{1F6FF}]/, "") # Remove emoji transport
         .gsub(/[\u{1F1E0}-\u{1F1FF}]/, "") # Remove emoji flags
         .gsub(/[\u{2600}-\u{26FF}]/, "")   # Remove emoji misc symbols
         .gsub(/[\u{2700}-\u{27BF}]/, "")   # Remove emoji dingbats
         .gsub(/[^\p{Print}\p{Space}]/, "") # Remove non-printable characters except spaces
         .strip
  end

  def log_font_availability
    font_paths = {
      "Noto Sans" => [
        "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
        "/usr/share/fonts/opentype/noto/NotoSans-Regular.otf",
        "/usr/share/fonts/TTF/NotoSans-Regular.ttf"
      ],
      "Noto Serif" => [
        "/usr/share/fonts/truetype/noto/NotoSerif-Regular.ttf",
        "/usr/share/fonts/opentype/noto/NotoSerif-Regular.otf",
        "/usr/share/fonts/TTF/NotoSerif-Regular.ttf"
      ],
      "Liberation Sans" => [
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
      ]
    }

    font_paths.each do |font_name, paths|
      available_path = paths.find { |path| File.exist?(path) }
      if available_path
        Rails.logger.info "✅ #{font_name} available at: #{available_path}"
      else
        Rails.logger.warn "❌ #{font_name} not found in paths: #{paths.join(', ')}"
      end
    end
  end

  def generate_prawn_from_template(resume, template_data, style)
    # Log font availability for debugging
    log_font_availability

    Prawn::Document.new(
      margin: [
        template_data[:styling][:margins][:top],
        template_data[:styling][:margins][:right],
        template_data[:styling][:margins][:bottom],
        template_data[:styling][:margins][:left]
      ]
    ) do |pdf|
      # Use UTF-8 compatible fonts
      begin
        # Try to use Noto fonts for better UTF-8 support
        noto_sans_paths = [
          "/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf",
          "/usr/share/fonts/opentype/noto/NotoSans-Regular.otf",
          "/usr/share/fonts/TTF/NotoSans-Regular.ttf"
        ]

        noto_serif_paths = [
          "/usr/share/fonts/truetype/noto/NotoSerif-Regular.ttf",
          "/usr/share/fonts/opentype/noto/NotoSerif-Regular.otf",
          "/usr/share/fonts/TTF/NotoSerif-Regular.ttf"
        ]

        # Find available Noto Sans font
        noto_sans_normal = noto_sans_paths.find { |path| File.exist?(path) }
        if noto_sans_normal
          pdf.font_families.update(
            "Noto Sans" => {
              normal: noto_sans_normal,
              bold: noto_sans_normal.gsub("Regular", "Bold"),
              italic: noto_sans_normal.gsub("Regular", "Italic"),
              bold_italic: noto_sans_normal.gsub("Regular", "BoldItalic")
            }
          )
        end

        # Find available Noto Serif font
        noto_serif_normal = noto_serif_paths.find { |path| File.exist?(path) }
        if noto_serif_normal
          pdf.font_families.update(
            "Noto Serif" => {
              normal: noto_serif_normal,
              bold: noto_serif_normal.gsub("Regular", "Bold"),
              italic: noto_serif_normal.gsub("Regular", "Italic"),
              bold_italic: noto_serif_normal.gsub("Regular", "BoldItalic")
            }
          )
        end

        # Try to use the requested font, fallback to Noto Sans if not available
        requested_font = template_data[:styling][:font_family]
        if pdf.font_families.key?(requested_font)
          pdf.font requested_font
        elsif pdf.font_families.key?("Noto Sans")
          pdf.font "Noto Sans"
        elsif File.exist?("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf")
          # Fallback to Liberation fonts
          pdf.font_families.update(
            "Liberation Sans" => {
              normal: "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
              bold: "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
              italic: "/usr/share/fonts/truetype/liberation/LiberationSans-Italic.ttf",
              bold_italic: "/usr/share/fonts/truetype/liberation/LiberationSans-BoldItalic.ttf"
            }
          )
          pdf.font "Liberation Sans"
        else
          # Use built-in fonts as last resort
          Rails.logger.warn "No external fonts available, using built-in fonts"
          pdf.font template_data[:styling][:font_family]
        end
      rescue => e
        Rails.logger.warn "Could not load external fonts for PDF: #{e.message}. Using built-in fonts."
        begin
          # Try to use built-in fonts with UTF-8 encoding
          pdf.font template_data[:styling][:font_family]
        rescue => font_error
          Rails.logger.error "Failed to use requested font '#{template_data[:styling][:font_family]}': #{font_error.message}"
          # Last resort: use default font
          pdf.font "Helvetica"
        end
      end

      pdf.font_size 10

      # Header
      pdf.font_size 24
      pdf.text template_data[:header][:name], style: :bold
      pdf.move_down 10

      # Contact info
      pdf.font_size 10
      pdf.text template_data[:header][:contact_info].join(" | "), color: "666666"
      pdf.move_down 20

      # Render each section
      template_data[:sections].each do |section_name, section_data|
        next unless section_data

        case section_name
        when :summary
          render_summary_section(pdf, section_data, style)
        when :skills
          render_skills_section(pdf, section_data, style)
        when :experience
          render_experience_section(pdf, section_data, style)
        when :education
          render_education_section(pdf, section_data, style)
        when :projects
          render_projects_section(pdf, section_data, style)
        end
      end
    end.render
  end

  def render_summary_section(pdf, section_data, style)
    pdf.font_size 16
    pdf.text section_data[:title], style: :bold
    pdf.move_down 8
    pdf.font_size 10
    pdf.text section_data[:content]
    pdf.move_down 15
  end

  def render_skills_section(pdf, section_data, style)
    pdf.font_size 16
    pdf.text section_data[:title], style: :bold
    pdf.move_down 8
    pdf.font_size 10
    skills_text = section_data[:content].join(section_data[:separator])
    pdf.text skills_text
    pdf.move_down 15
  end

  def render_experience_section(pdf, section_data, style)
    pdf.font_size 16
    pdf.text section_data[:title], style: :bold
    pdf.move_down 8

    section_data[:items].each do |exp|
      if style == "classic"
        # Classic layout: Company, Location | Title | Dates
        pdf.font_size 12
        pdf.text "#{exp[:company].upcase}, #{exp[:location]}", style: :bold
        pdf.move_down 2
        pdf.font_size 10
        pdf.text exp[:title], style: :bold
        pdf.text "#{exp[:start_date]&.strftime("%Y")} - #{exp[:end_date]&.strftime("%Y") || "Present"}", color: "666666"
      else
        # Modern layout: Title @ Company | Location | Dates
        pdf.font_size 12
        pdf.text "#{exp[:title]} @ #{exp[:company]}", style: :bold
        pdf.font_size 10
        pdf.text "#{exp[:location]} · #{exp[:start_date]&.strftime("%b %Y")} – #{exp[:end_date]&.strftime("%b %Y") || "Present"}", color: "666666"
      end

      pdf.move_down 5

      if exp[:responsibilities].any?
        exp[:responsibilities].each do |resp|
          pdf.text "• #{resp}"
          pdf.move_down 2
        end
      end
      pdf.move_down 10
    end
  end

  def render_education_section(pdf, section_data, style)
    pdf.font_size 16
    pdf.text section_data[:title], style: :bold
    pdf.move_down 8

    section_data[:items].each do |edu|
      if style == "classic"
        pdf.font_size 12
        pdf.text edu[:school].upcase, style: :bold
        pdf.font_size 10
        pdf.text "#{edu[:field]} · #{edu[:start_date]&.year} – #{edu[:end_date]&.year || "Present"}", color: "666666"
      else
        pdf.font_size 12
        pdf.text edu[:school], style: :bold
        pdf.font_size 10
        pdf.text "#{edu[:field]} · #{edu[:start_date]&.year} – #{edu[:end_date]&.year || "Present"}", color: "666666"
      end
      pdf.move_down 10
    end
  end

  def render_projects_section(pdf, section_data, style)
    pdf.font_size 16
    pdf.text section_data[:title], style: :bold
    pdf.move_down 8

    section_data[:items].each do |proj|
      pdf.font_size 12
      title = style == "classic" ? proj[:title].upcase : proj[:title]
      pdf.text title, style: :bold

      if proj[:url].present?
        pdf.font_size 10
        pdf.text proj[:url], color: style == "classic" ? "666666" : "0066cc"
      end

      if proj[:description].present?
        pdf.move_down 5
        pdf.text proj[:description]
      end
      pdf.move_down 10
    end
  end

  def set_resume
    if current_user
      @resume = current_user.resume
    else
      @resume = nil
    end
  end

  def set_resume_for_destroy
    @resume = if params[:slug]
      current_user.resumes.find_by(slug: params[:slug])
    else
      current_user.resume
    end
    unless @resume
      redirect_to((params[:slug] ? resumes_path : resume_path), alert: "Resume not found.")
    end
  end

  def set_resume_public
    @resume = Resume.find_by(slug: params[:slug])
    unless @resume
      flash[:alert] = "😭 The resume you're looking for doesn't exist or may have been removed."
      redirect_to root_path
      nil
    end
  end

  def track_guest_public_resume_view
    return unless current_user&.guest? && current_user.resume&.id == @resume&.id

    GuestActivity.track!(
      event_type: "public_resume_view",
      guest_user: current_user,
      session_id: session.id&.to_s
    )
  end

  def track_guest_pdf_view
    return unless current_user&.guest? && current_user.resume&.id == @resume&.id

    GuestActivity.track!(
      event_type: "pdf_view",
      guest_user: current_user,
      session_id: session.id&.to_s
    )
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
