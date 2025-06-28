module ResumesHelper
  def user_full_name(resume)
    "#{resume.user_first_name} #{resume.user_last_name}"
  end

  def styled_telephone_number(resume)
    return nil unless resume.user_phone.present?
    resume.user_phone.gsub(/(\d{3})(\d{3})(\d{4})/, '(\1) \2-\3')
  end
end
