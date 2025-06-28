module ApplicationHelper
  def track_ga_event(event_name, parameters = {})
    return unless Rails.env.production?

    content_tag :script, type: "text/javascript" do
      "gtag('event', '#{event_name}', #{parameters.to_json});".html_safe
    end
  end
end
