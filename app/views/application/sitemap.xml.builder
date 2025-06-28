xml.instruct!
xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
  # Homepage
  xml.url do
    xml.loc "https://freeresumebuilderapp.com/"
    xml.lastmod Time.current.strftime("%Y-%m-%d")
    xml.changefreq "weekly"
    xml.priority "1.0"
  end

  # Public resume pages
  @resumes.each do |resume|
    xml.url do
      xml.loc "https://freeresumebuilderapp.com/r/#{resume.slug}"
      xml.lastmod resume.updated_at.strftime("%Y-%m-%d")
      xml.changefreq "monthly"
      xml.priority "0.8"
    end
  end
end
