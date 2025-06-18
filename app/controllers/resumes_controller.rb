class ResumesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_resume

  def show; end

  def edit; end

  def update
    if @resume.update(resume_params)
      redirect_to resume_path, notice: "Resume updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_resume
    @resume = current_user.resume
  end

  def resume_params
    params.require(:resume).permit(
      :summary,
      skills_attributes: [ :id, :name, :_destroy ],
      educations_attributes: [ :id, :school, :location, :field_of_study, :start_date, :end_date, :_destroy ],
      projects_attributes: [ :id, :title, :description, :url, :_destroy ]
    )
  end
end
