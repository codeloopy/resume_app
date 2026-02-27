# frozen_string_literal: true

class AtsAnalyzerService
  MAX_SCORE = 100

  # Common ATS-unfriendly characters that may cause parsing issues
  UNFRIENDLY_CHARS = %w[• ★ ● ◆ ■ ✓ ✗ → ← ⇒].freeze

  def initialize(resume)
    @resume = resume
  end

  def analyze
    {
      score: calculate_score,
      grade: grade_for_score(calculate_score),
      suggestions: build_suggestions,
      breakdown: build_breakdown
    }
  end

  private

  def calculate_score
    [
      contact_info_score,      # 15 pts
      summary_score,           # 20 pts
      skills_score,            # 15 pts
      experience_score,        # 25 pts
      education_score,         # 15 pts
      formatting_score        # 10 pts
    ].sum
  end

  def contact_info_score
    score = 0
    score += 5 if @resume.user_first_name.present? && @resume.user_last_name.present?
    score += 5 if @resume.user_email.present?
    score += 5 if @resume.user_phone.present?
    score
  end

  def summary_score
    return 0 unless @resume.summary.present?

    text = @resume.summary.to_plain_text.strip
    word_count = text.split.size

    if word_count < 25
      10 # Too short
    elsif word_count >= 25 && word_count <= 150
      20 # Ideal length
    elsif word_count <= 250
      15 # Acceptable but long
    else
      10 # Too long
    end
  end

  def skills_score
    count = @resume.skills.count
    return 0 if count.zero?
    return 10 if count < 3
    return 15 if count >= 5

    12 # 3-4 skills
  end

  def experience_score
    return 0 if @resume.experiences.empty?

    score = 10 # Has experience
    score += 5 if @resume.experiences.any? { |e| e.start_date.present? }
    score += 5 if @resume.experiences.any? { |e| e.responsibilities.any? }
    score += 5 if @resume.experiences.count >= 2
    score
  end

  def education_score
    return 0 if @resume.educations.empty?

    score = 10 # Has education
    score += 5 if @resume.educations.any? { |e| e.school.present? && e.field_of_study.present? }
    score
  end

  def formatting_score
    score = 10
    full_text = extract_full_text
    UNFRIENDLY_CHARS.each do |char|
      score -= 2 if full_text.include?(char)
    end
    score = [ score, 0 ].max
  end

  def extract_full_text
    parts = []
    parts << @resume.summary.to_plain_text if @resume.summary.present?
    parts << @resume.title if @resume.title.present?
    @resume.experiences.each do |exp|
      parts << exp.title << exp.company_name
      exp.responsibilities.each { |r| parts << r.content }
    end
    @resume.skills.each { |s| parts << s.name }
    @resume.educations.each { |e| parts << e.school << e.field_of_study }
    parts.join(" ")
  end

  def grade_for_score(score)
    case score
    when 90..100 then "A"
    when 80..89 then "B+"
    when 70..79 then "B"
    when 60..69 then "C+"
    when 50..59 then "C"
    else "Needs Work"
    end
  end

  def build_suggestions
    suggestions = []

    # Contact info
    suggestions << "Add your phone number for better recruiter contact" if @resume.user_phone.blank?
    suggestions << "Ensure your name and email are complete" if @resume.user_first_name.blank? || @resume.user_email.blank?

    # Summary
    if @resume.summary.blank?
      suggestions << "Add a professional summary (2-4 sentences) highlighting your key strengths"
    else
      word_count = @resume.summary.to_plain_text.split.size
      suggestions << "Shorten your summary to 50-150 words for better ATS parsing" if word_count > 150
      suggestions << "Expand your summary to at least 50 words" if word_count < 25
    end

    # Skills
    suggestions << "Add at least 5 relevant skills—ATS systems often match on keywords" if @resume.skills.count < 5 && @resume.skills.any?
    suggestions << "Add a skills section with industry-relevant keywords" if @resume.skills.empty?

    # Experience
    suggestions << "Add work experience with clear job titles and company names" if @resume.experiences.empty?
    suggestions << "Include bullet points with quantifiable achievements" if @resume.experiences.any? && @resume.experiences.none? { |e| e.responsibilities.count >= 2 }
    suggestions << "Add start and end dates to all experience entries" if @resume.experiences.any? { |e| e.start_date.blank? }

    # Education
    suggestions << "Add your education with school name and field of study" if @resume.educations.empty?

    # Formatting
    full_text = extract_full_text
    if UNFRIENDLY_CHARS.any? { |char| full_text.include?(char) }
      suggestions << "Replace special characters (•, ★, etc.) with standard bullets (-) for better ATS compatibility"
    end

    suggestions.first(5) # Top 5 most impactful
  end

  def build_breakdown
    {
      contact_info: { score: contact_info_score, max: 15, label: "Contact Information" },
      summary: { score: summary_score, max: 20, label: "Professional Summary" },
      skills: { score: skills_score, max: 15, label: "Skills & Keywords" },
      experience: { score: experience_score, max: 25, label: "Work Experience" },
      education: { score: education_score, max: 15, label: "Education" },
      formatting: { score: formatting_score, max: 10, label: "ATS-Friendly Formatting" }
    }
  end
end
