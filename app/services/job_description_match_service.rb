# frozen_string_literal: true

class JobDescriptionMatchService
  STOP_WORDS = %w[
    a an and are as at be by for from has have he her his i in is it its
    of on or that the their them they this to was we were will with you your
    our us about into over under through during before after above below
    am been being do does did doing had having would could should may might
    must shall can need all any both each few more most other some such no
    nor not only own same so than too very just also than then once here
  ].freeze

  MIN_KEYWORD_LENGTH = 3
  MAX_KEYWORDS = 50

  def initialize(resume, job_description:)
    @resume = resume
    @job_description = job_description.to_s
  end

  def analyze
    resume_keywords = extract_keywords(resume_text)
    job_keywords = extract_keywords(@job_description)

    matched = (resume_keywords & job_keywords).sort
    missing = (job_keywords - resume_keywords).sort.first(MAX_KEYWORDS)
    match_score = calculate_score(matched.size, job_keywords.size)

    {
      match_score: match_score,
      matched_keywords: matched,
      missing_keywords: missing,
      total_job_keywords: job_keywords.size,
      total_resume_keywords: resume_keywords.size,
      matched_count: matched.size
    }
  end

  private

  def resume_text
    parts = []
    parts << @resume.summary.to_plain_text if @resume.summary.present?
    parts << @resume.title if @resume.title.present?
    @resume.skills.each { |skill| parts << skill.name }
    @resume.experiences.each do |exp|
      parts << exp.title << exp.company_name
      exp.responsibilities.each { |r| parts << r.content }
    end
    @resume.educations.each do |edu|
      parts << edu.school << edu.field_of_study
    end
    @resume.projects.each do |project|
      parts << project.title << project.description
    end
    parts.compact.join(" ")
  end

  def extract_keywords(text)
    text.downcase
        .gsub(/[^a-z0-9+#.\s-]/, " ")
        .split(/\s+/)
        .map { |word| word.gsub(/\A-+|-+\z/, "") }
        .select { |word| keyword?(word) }
        .uniq
  end

  def keyword?(word)
    return false if word.length < MIN_KEYWORD_LENGTH
    return false if STOP_WORDS.include?(word)

    true
  end

  def calculate_score(matched_count, job_keyword_count)
    return 0 if job_keyword_count.zero?

    ((matched_count.to_f / job_keyword_count) * 100).round.clamp(0, 100)
  end
end
