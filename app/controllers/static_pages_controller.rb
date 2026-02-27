class StaticPagesController < ApplicationController
  def pricing
  end

  def home
    # Set cache headers for the static landing page
    # Set cache expiration to 1 hour and make it publicly cacheable
    expires_in 1.hour, public: true

    # Use conditional GET with ETag and Last-Modified headers
    # ETag is a version identifier for the content
    # Last-Modified is set to 1 hour ago to match cache expiration
    fresh_when(etag: "static_pages_home_v1", last_modified: 1.hour.ago)
  end
end
