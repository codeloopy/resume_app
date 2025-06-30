module ResumesHelper
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
end
