module SkillsHelper
  def skill_field_html(skill_name: "", skill_id: nil, index: "NEW_RECORD", new_record: false)
    html = <<~HTML
      <div class="nested-fields mb-2 flex items-start space-x-2" data-new-record="#{new_record}">
        <input type="text" name="resume[skills_attributes][#{index}][name]" value="#{skill_name}" class="w-full p-2 border border-gray-300 rounded-md" placeholder="Enter skill name">
        <a href="#" class="text-red-500" data-action="click->responsibility#remove">&times;</a>
        <input type="hidden" name="resume[skills_attributes][#{index}][_destroy]" value="0">
    HTML

    if skill_id
      html += "<input type=\"hidden\" name=\"resume[skills_attributes][#{index}][id]\" value=\"#{skill_id}\">"
    end

    html += "</div>"
    html.html_safe
  end
end
