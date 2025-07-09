class EducationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_education, only: [ :edit, :update, :destroy ]

  def new
    @resume = current_user.resume
    @education = @resume.educations.new
  end

  def create
    @resume = current_user.resume
    @education = @resume.educations.new(education_params)
    if @education.save
      redirect_to resume_wizard_path(:education), notice: "Education added successfully! Continue with the wizard."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @resume = current_user.resume
  end

  def update
    @resume = current_user.resume
    if @education.update(education_params)
      redirect_to resume_wizard_path(:education), notice: "Education updated successfully! Continue with the wizard."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @education.destroy
    redirect_to resume_wizard_path(:education), notice: "Education removed successfully! Continue with the wizard."
  end

  private

  def set_education
    @education = current_user.resume.educations.find(params[:id])
  end

  def education_params
    params.require(:education).permit(:school, :location, :field_of_study, :start_date, :end_date)
  end
end
