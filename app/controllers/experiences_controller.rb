class ExperiencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_experience, only: [ :edit, :update, :destroy ]

  def new
    @experience = current_user.resume.experiences.new
  end

  def create
    @experience = current_user.resume.experiences.new(experience_params)
    if @experience.save
      redirect_to resume_wizard_path(:experience), notice: "Experience added successfully! Continue with the wizard."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @experience.update(experience_params)
      redirect_to resume_wizard_path(:experience), notice: "Experience updated successfully! Continue with the wizard."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @experience.destroy
    redirect_to resume_wizard_path(:experience), notice: "Experience removed successfully! Continue with the wizard."
  end

  private

  def set_experience
    @experience = current_user.resume.experiences.find(params[:id])
  end

  def experience_params
    params.require(:experience).permit(:company_name, :location, :title, :start_date, :end_date, responsibilities_attributes: [ :id, :content, :_destroy ])
  end
end
