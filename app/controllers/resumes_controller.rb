class ResumesController < ApplicationController
  before_action :authenticate_user!, except: [ :show, :public, :public_pdf, :public_pdf_download, :public_pdf_modern, :public_pdf_classic ]
  before_action :set_resume_public, only: [ :public, :public_pdf, :public_pdf_download, :public_pdf_modern, :public_pdf_classic ]
  before_action :set_resume, except: [ :public, :public_pdf, :public_pdf_download, :public_pdf_modern, :public_pdf_classic ]

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
      render plain: "PDF generation timed out", status: :request_timeout

    rescue Grover::JavaScript::UnknownError => e
      Rails.logger.error "Grover JavaScript error: #{e.message}"
      Rails.logger.error "Grover error details: #{e.inspect}"
      render plain: "PDF generation failed", status: :internal_server_error

    rescue => e
      Rails.logger.error "PDF generation error: #{e.message}"
      Rails.logger.error "Error class: #{e.class}"
      render plain: "PDF generation failed", status: :internal_server_error
    end
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
