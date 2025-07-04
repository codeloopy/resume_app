namespace :debug do
  desc "Debug resume slugs and find missing ones"
  task resumes: :environment do
    puts "=== Resume Debug Information ==="
    puts "Total resumes: #{Resume.count}"

    if Resume.count > 0
      puts "\n=== Resume Details ==="
      Resume.includes(:user).each do |resume|
        puts "ID: #{resume.id}"
        puts "  Slug: #{resume.slug}"
        puts "  User: #{resume.user&.first_name} #{resume.user&.last_name}"
        puts "  User ID: #{resume.user_id}"
        puts "  Created: #{resume.created_at}"
        puts "  Updated: #{resume.updated_at}"
        puts "---"
      end
    else
      puts "No resumes found in database"
    end

    puts "\n=== Users without resumes ==="
    User.left_joins(:resume).where(resumes: { id: nil }).each do |user|
      puts "User ID: #{user.id}, Name: #{user.first_name} #{user.last_name}, Email: #{user.email}"
    end
  end

  desc "Generate missing slugs for existing resumes"
  task generate_slugs: :environment do
    puts "=== Generating missing slugs ==="
    resumes_without_slugs = Resume.where(slug: nil)
    puts "Found #{resumes_without_slugs.count} resumes without slugs"

    resumes_without_slugs.each do |resume|
      old_slug = resume.slug
      resume.send(:generate_slug)
      puts "Resume ID #{resume.id}: #{old_slug} -> #{resume.slug}"
      resume.save!
    end

    puts "Slug generation complete!"
  end

  desc "Fix all resume slugs to ensure consistency"
  task fix_slugs: :environment do
    puts "=== Fixing all resume slugs ==="
    total_resumes = Resume.count
    puts "Total resumes to process: #{total_resumes}"

    Resume.includes(:user).each_with_index do |resume, index|
      old_slug = resume.slug
      resume.regenerate_slug!
      puts "[#{index + 1}/#{total_resumes}] Resume ID #{resume.id}: #{old_slug} -> #{resume.slug}"
    end

    puts "Slug fixing complete!"
  end
end
