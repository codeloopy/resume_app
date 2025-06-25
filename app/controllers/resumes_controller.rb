class ResumesController < ApplicationController
  before_action :authenticate_user!, except: :show
  before_action :set_resume
  before_action :set_resume_public, only: [ :public, :public_pdf ]

  def show; end

  def edit; end

  def update
    Rails.logger.info "Resume update params: #{resume_params.inspect}"

    if @resume.update(resume_params)
      Rails.logger.info "Resume updated successfully"
      Rails.logger.info "Skills after update: #{@resume.skills.reload.map(&:name)}"
      redirect_to resume_path, notice: "Resume updated!"
    else
      Rails.logger.error "Resume update failed: #{@resume.errors.full_messages}"
      Rails.logger.error "Skills errors: #{@resume.skills.map { |s| s.errors.full_messages }.flatten}"
      render :edit, status: :unprocessable_entity
    end
  end

  def public
  end

  def public_pdf
    @resume = Resume.find_by!(slug: params[:slug])

    # Render HTML first to catch any template errors
    html = render_to_string(
      template: "resumes/public_pdf",
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
        disposition = params[:download] == "true" ? "attachment" : "inline"

        # Set proper headers for PDF display
        response.headers["Content-Type"] = "application/pdf"
        response.headers["Content-Disposition"] = "#{disposition}; filename=\"#{@resume.user_first_name}_resume.pdf\""
        response.headers["Content-Length"] = pdf_data.length.to_s
        response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"

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
      render template: "resumes/public_pdf", layout: "pdf", locals: { resume: @resume }, formats: [ :html ]

    rescue Grover::JavaScript::UnknownError => e
      Rails.logger.error "Grover JavaScript error: #{e.message}"
      Rails.logger.error "Grover error details: #{e.inspect}"
      Rails.logger.error "Grover error backtrace: #{e.backtrace.first(5).join("\n")}"

      # Fallback: return HTML instead of PDF
      render template: "resumes/public_pdf", layout: "pdf", locals: { resume: @resume }, formats: [ :html ]

    rescue => e
      Rails.logger.error "PDF generation error: #{e.message}"
      Rails.logger.error "Error class: #{e.class}"
      Rails.logger.error "Error backtrace: #{e.backtrace.first(5).join("\n")}"

      # Fallback: return HTML instead of PDF
      render template: "resumes/public_pdf", layout: "pdf", locals: { resume: @resume }, formats: [ :html ]
    end
  end

  private

  def set_resume
    @resume = current_user.resume
  end

  def set_resume_public
    @resume = Resume.find_by!(slug: params[:slug])
  end

  def resume_params
    params.require(:resume).permit(
      :summary, :title,
      skills_attributes: [ :id, :name, :_destroy ],
      educations_attributes: [ :id, :school, :location, :field_of_study, :start_date, :end_date, :_destroy ],
      projects_attributes: [ :id, :title, :description, :url, :_destroy ]
    )
  end
end
