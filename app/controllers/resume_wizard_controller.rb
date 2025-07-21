class ResumeWizardController < ApplicationController
  include Wicked::Wizard

  steps :summary, :experience, :skills, :education, :projects

  before_action :authenticate_user!
  before_action :set_resume

  # Make steps available to views
  helper_method :steps

  def show
    Rails.logger.info "ResumeWizardController#show: step=#{step.inspect}, params=#{params.inspect}"
    render_wizard
  end

  def update
    case step
    when :summary
      @resume.assign_attributes(resume_params)
    when :experience
      # Experience is managed separately via experiences controller
    when :skills
      @resume.assign_attributes(resume_params)
    when :education
      # Education is managed separately via educations controller
    when :projects
      @resume.assign_attributes(resume_params)
    end

    if @resume.save
      render_wizard @resume
    else
      render_wizard @resume, status: :unprocessable_entity
    end
  end

  def finish_wizard_path
    # resume_path
    public_resume_path(@resume)
  end

  def after_finish_wizard_path
    # resume_path
    public_resume_path(@resume)
  end

  private

  def set_resume
    @resume = current_user.resume
    unless @resume
      flash[:alert] = "Please sign up to create your resume."
      redirect_to new_user_registration_path
    end
  end

  def resume_params
    params.require(:resume).permit(
      :title, :summary, :skills_title, :pdf_template,
      skills_attributes: [ :id, :name, :_destroy ]
    )
  end
end
