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

    html = render_to_string(
      template: "resumes/public_pdf",
      layout: "pdf",
      formats: [ :html ]
    )

    grover = Grover.new(html, format: "A4")
    send_data grover.to_pdf,
              filename: "#{@resume.user_first_name}_resume.pdf",
              type: "application/pdf",
              disposition: "inline"
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
