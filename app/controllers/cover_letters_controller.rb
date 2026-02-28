# frozen_string_literal: true

class CoverLettersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_cover_letter_access
  before_action :set_resume
  before_action :set_cover_letter, only: [ :show, :edit, :update, :destroy, :pdf ]

  def index
    @cover_letters = @resume.cover_letters.order(updated_at: :desc)
  end

  def show
  end

  def new
    @cover_letter = @resume.cover_letters.build
  end

  def create
    @cover_letter = @resume.cover_letters.build(cover_letter_params)

    if @cover_letter.save
      redirect_to resume_cover_letter_path(@resume, @cover_letter), notice: "Cover letter created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @cover_letter.update(cover_letter_params)
      redirect_to resume_cover_letter_path(@resume, @cover_letter), notice: "Cover letter updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cover_letter.destroy
    redirect_to resume_cover_letters_path(@resume), notice: "Cover letter deleted."
  end

  def generate
    @cover_letter = @resume.cover_letters.build(cover_letter_params)
    use_ai = params[:use_ai] == "true" && ENV["OPENAI_API_KEY"].present?

    CoverLetterGeneratorService.new(@cover_letter).generate(use_ai: use_ai)
    @cover_letter.save!

    redirect_to edit_resume_cover_letter_path(@resume, @cover_letter), notice: "Cover letter generated. Review and edit as needed."
  rescue ActiveRecord::RecordInvalid => e
    @cover_letter = @resume.cover_letters.build(cover_letter_params)
    flash.now[:alert] = "Could not generate: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def pdf
    html = render_to_string(
      template: "cover_letters/pdf",
      layout: "pdf",
      formats: [ :html ],
      locals: { cover_letter: @cover_letter }
    )

    grover = Grover.new(html)
    pdf_data = grover.to_pdf

    filename = "cover_letter_#{@cover_letter.display_title.parameterize}.pdf"

    send_data pdf_data,
              filename: filename,
              type: "application/pdf",
              disposition: "attachment"
  rescue => e
    Rails.logger.error "Cover letter PDF error: #{e.message}"
    redirect_to resume_cover_letter_path(@resume, @cover_letter), alert: "PDF generation failed. Please try again."
  end

  private

  def require_cover_letter_access
    return if current_user.cover_letter_access?

    redirect_to pricing_path, alert: "Cover letters are a Growth & Pro feature. Upgrade to create cover letters."
  end

  def set_resume
    @resume = current_user.resumes.find_by!(slug: params[:resume_slug])
  end

  def set_cover_letter
    @cover_letter = @resume.cover_letters.find(params[:id])
  end

  def cover_letter_params
    params.require(:cover_letter).permit(:title, :company_name, :job_title, :job_description, :content)
  end
end
