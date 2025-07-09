class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [ :edit, :update, :destroy ]

  def new
    @resume = current_user.resume
    @project = @resume.projects.new
  end

  def create
    @resume = current_user.resume
    @project = @resume.projects.new(project_params)
    if @project.save
      redirect_to resume_wizard_path(:projects), notice: "Project added successfully! Continue with the wizard."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @resume = current_user.resume
  end

  def update
    @resume = current_user.resume
    if @project.update(project_params)
      redirect_to resume_wizard_path(:projects), notice: "Project updated successfully! Continue with the wizard."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to resume_wizard_path(:projects), notice: "Project removed successfully! Continue with the wizard."
  end

  private

  def set_project
    @project = current_user.resume.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:title, :description, :url)
  end
end
