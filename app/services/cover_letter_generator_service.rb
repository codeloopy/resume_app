# frozen_string_literal: true

class CoverLetterGeneratorService
  def initialize(cover_letter)
    @cover_letter = cover_letter
    @resume = cover_letter.resume
    @user = @resume.user
  end

  def generate(use_ai: false)
    if use_ai && ai_available?
      generate_with_ai
    else
      generate_template_based
    end
  end

  private

  attr_reader :cover_letter, :resume, :user

  def generate_template_based
    job_desc = cover_letter.job_description.to_s
    company = cover_letter.company_name.presence || "the company"
    job_title = cover_letter.job_title.presence || "the position"

    intro = build_intro(company, job_title)
    body = build_body(job_desc)
    closing = build_closing(company)

    full_content = [ intro, body, closing ].compact.join("\n\n")
    cover_letter.content = full_content
    cover_letter
  end

  def build_intro(company, job_title)
    name = user.full_name
    resume_title = resume.title.presence || "professional"
    [
      "Dear Hiring Manager,",
      "",
      "I am writing to express my interest in the #{job_title} position at #{company}. " \
      "As a #{resume_title} with relevant experience, I am excited about the opportunity to contribute to your team."
    ].join("\n")
  end

  def build_body(job_desc)
    paragraphs = []

    # Highlight relevant experience
    if resume.experiences.any?
      exp = resume.experiences.first
      exp_summary = "At #{exp.company_name}, I #{exp.responsibilities.first&.content&.truncate(150) || 'gained valuable experience'}."
      paragraphs << exp_summary
    end

    # Reference job description if provided
    if job_desc.present?
      paragraphs << "I have reviewed the job requirements and believe my background aligns well with what you are seeking. " \
        "I am particularly drawn to this opportunity and am confident I can make a positive impact."
    end

    # Skills match
    if resume.skills.any?
      skills_sample = resume.skills.limit(5).pluck(:name).join(", ")
      paragraphs << "My skills in #{skills_sample} would allow me to hit the ground running."
    end

    paragraphs.join("\n\n")
  end

  def build_closing(company)
    [
      "I would welcome the opportunity to discuss how my experience can benefit #{company}. " \
      "Thank you for considering my application.",
      "",
      "Sincerely,",
      user.full_name
    ].join("\n")
  end

  def ai_available?
    ENV["OPENAI_API_KEY"].present?
  end

  def generate_with_ai
    # Optional: integrate OpenAI for AI-generated cover letters
    # For now, fall back to template-based
    generate_template_based
  end
end
