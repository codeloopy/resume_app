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
    params.require(:resume).permit(:summary)
  end
end
