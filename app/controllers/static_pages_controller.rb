class StaticPagesController < ApplicationController
  def home
    # Set cache headers for the static landing page
    expires_in 1.hour, public: true
    fresh_when(etag: "static_pages_home_v1", last_modified: 1.hour.ago)
  end
end
