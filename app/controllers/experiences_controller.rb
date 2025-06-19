class ExperiencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_experience, only: [ :edit, :update, :destroy ]

  def new
    @experience = current_user.resume.experiences.new
  end

  def create
    @experience = current_user.resume.experiences.new(experience_params)
    if @experience.save
      redirect_to edit_resume_path, notice: "Experience added"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @experience.update(experience_params)
      redirect_to edit_resume_path, notice: "Experience updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @experience.destroy
    redirect_to edit_resume_path, notice: "Experience removed"
  end

  private

  def set_experience
    @experience = current_user.resume.experiences.find(params[:id])
  end

  def experience_params
    params.require(:experience).permit(:company_name, :location, :title, :start_date, :end_date, responsibilities_attributes: [ :id, :content, :_destroy ])
  end
end
