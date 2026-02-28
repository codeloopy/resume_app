# frozen_string_literal: true

module JobApplicationsHelper
  def status_badge_class(status)
    case status.to_s
    when "offer" then "bg-green-100 text-green-800"
    when "interview", "screening" then "bg-blue-100 text-blue-800"
    when "applied" then "bg-gray-100 text-gray-800"
    when "rejected", "withdrawn" then "bg-red-100 text-red-800"
    when "draft" then "bg-yellow-100 text-yellow-800"
    else "bg-gray-100 text-gray-800"
    end
  end
end
