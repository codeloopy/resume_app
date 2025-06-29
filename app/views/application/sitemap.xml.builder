xml.instruct!
xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
  # Homepage
  xml.url do
    xml.loc "https://freeresumebuilderapp.com/"
    xml.lastmod Time.current.strftime("%Y-%m-%d")
    xml.changefreq "weekly"
    xml.priority "1.0"
  end

  # Public resume pages with enhanced data
  if @resumes.present?
    @resumes.each do |resume|
      xml.url do
        xml.loc "https://freeresumebuilderapp.com/r/#{resume.slug}"
        xml.lastmod resume.updated_at.strftime("%Y-%m-%d")
        xml.changefreq "monthly"
        xml.priority "0.8"

        # Add image for rich snippets
        xml.image do
          xml.image_loc "https://freeresumebuilderapp.com/icon.png"
          xml.image_title "#{resume.user_first_name} #{resume.user_last_name} - #{resume.title || 'Professional Resume'}"
          xml.image_caption "#{resume.user_first_name} #{resume.user_last_name} - #{resume.title || 'Professional Resume'}"
        end
      end
    end
  end
end
