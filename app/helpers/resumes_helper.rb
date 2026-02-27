module ResumesHelper
  def pdf_template_options_for_select(current_value)
    free_options = [
      [ "Modern - Clean and contemporary", "modern" ],
      [ "Classic - Traditional and professional", "classic" ]
    ]
    premium_options = [
      [ "Minimal - Ultra-clean, maximum whitespace", "minimal" ],
      [ "Creative - Elegant with accent styling", "creative" ],
      [ "Executive - Formal, centered layout", "executive" ]
    ]

    if current_user&.pro? || current_user&.growth?
      options_for_select(free_options + premium_options, current_value)
    else
      options = free_options.map { |label, value| [ label, value ] }
      options += premium_options.map { |label, value| [ label, value, { disabled: true } ] }
      options_for_select(options, current_value)
    end
  end

  def user_full_name(resume)
    "#{resume.user_first_name} #{resume.user_last_name}"
  end

  def styled_telephone_number(phone)
    return nil unless phone.present?
    if phone.length == 10
      phone.gsub(/(\d{3})(\d{3})(\d{4})/, '(\1) \2-\3')
    else
      phone.gsub(/^\+?1?\(?(\d{3})\)?[-.\s]?(\d{3})[-.\s]?(\d{4})$/, '(\1) \2-\3')
    end
  end

  def resume_completed(resume)
    if resume
      resume.summary.present? ||
      resume.experiences.present? ||
      resume.educations.present?
    end
  end
end
