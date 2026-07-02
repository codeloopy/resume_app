# frozen_string_literal: true

class JobApplicationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_job_application_access
  before_action :set_resume
  before_action :set_job_application, only: [ :show, :edit, :update, :destroy ]

  def index
    @job_applications = @resume.job_applications
                               .by_status(params[:status])
                               .recent_first
  end

  def show
  end

  def new
    @job_application = @resume.job_applications.build(applied_at: Date.current)
  end

  def create
    @job_application = @resume.job_applications.build(job_application_params)

    if @job_application.save
      redirect_to resume_job_application_path(@resume, @job_application), notice: "Application added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @job_application.update(job_application_params)
      redirect_path = params[:from] == "index" ? resume_job_applications_path(@resume) : resume_job_application_path(@resume, @job_application)
      redirect_to redirect_path, notice: "Application updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @job_application.destroy
    redirect_to resume_job_applications_path(@resume), notice: "Application removed."
  end

  private

  def require_job_application_access
    return if current_user.job_application_access?

    redirect_to pricing_path, alert: "Job Application Tracker is a Pro feature. Upgrade to track your applications."
  end

  def set_resume
    @resume = current_user.resumes.find_by!(slug: params[:resume_slug])
  end

  def set_job_application
    @job_application = @resume.job_applications.find(params[:id])
  end

  def job_application_params
    permitted = params.require(:job_application).permit(:company, :role, :notes, :applied_at, :next_follow_up_at)
    status = params.dig(:job_application, :status)
    permitted[:status] = status if status.in?(JobApplication::STATUSES)
    permitted
  end
end
