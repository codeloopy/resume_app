module Admin::DashboardHelper
  def role_badge(role)
    case role
    when "admin"
      "text-center uppercase bg-green-100 text-green-800 text-xs font-bold mr-2 px-2.5 py-1 rounded-full"
    when "user"
      "text-center uppercase bg-violet-100 text-violet-800 text-xs font-bold mr-2 px-2.5 py-1 rounded-full "
    end
  end

  def resume_completed_badge(completed)
    if completed
      "text-center uppercase bg-red-100 text-red-800 text-xs font-bold mr-2 px-2.5 py-1 rounded-full"
    else
      "text-center uppercase bg-green-100 text-green-800 text-xs font-bold mr-2 px-2.5 py-1 rounded-full"
    end
  end

  def true_false_badge(boolean)
    if boolean
      content_tag(:td, class: "p-4 border-b border-slate-200", data: { "tooltip-target": "tooltip-default", "tooltip-placement": "top" }) do
        content_tag(:p, "Yes", class: "text-center uppercase bg-green-100 text-green-800 text-xs font-bold mr-2 px-2.5 py-1 rounded-full")
      end
    else
      content_tag(:td, class: "p-4 border-b border-slate-200", data: { "tooltip-target": "tooltip-default", "tooltip-placement": "top" }) do
        content_tag(:p, "No", class: "text-center uppercase bg-red-100 text-red-800 text-xs font-bold mr-2 px-2.5 py-1 rounded-full")
      end
    end
  end
end
