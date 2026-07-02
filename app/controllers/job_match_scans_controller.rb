# frozen_string_literal: true

class JobMatchScansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_resume
  before_action :set_scan, only: :show

  def index
    @scans = @resume.job_match_scans.recent_first
    @quota = current_user.usage_quota
  end

  def new
    @scan = @resume.job_match_scans.build
  end

  def create
    unless current_user.usage_quota.can_scan_job_description?
      redirect_to pricing_path, alert: "You've used all your job match scans this month. Upgrade for more."
      return
    end

    job_description = scan_params[:job_description].to_s
    result = JobDescriptionMatchService.new(@resume, job_description: job_description).analyze

    @scan = @resume.job_match_scans.build(scan_params.merge(
      match_score: result[:match_score],
      result: result
    ))

    if @scan.save
      current_user.usage_quota.consume_jd_scan!
      redirect_to resume_job_match_scan_path(@resume, @scan), notice: "Job match analysis complete."
    else
      render :new, status: :unprocessable_entity
    end
  rescue UsageQuota::LimitExceeded
    redirect_to pricing_path, alert: "You've used all your job match scans this month. Upgrade for more."
  end

  def show
    @result = @scan.result.symbolize_keys
    @quota = current_user.usage_quota
  end

  private

  def set_resume
    @resume = current_user.resumes.find_by!(slug: params[:resume_slug])
  end

  def set_scan
    @scan = @resume.job_match_scans.find(params[:id])
  end

  def scan_params
    params.require(:job_match_scan).permit(:job_title, :company_name, :job_description)
  end
end
