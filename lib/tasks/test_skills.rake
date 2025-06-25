namespace :skills do
  desc "Test skills functionality"
  task test: :environment do
    puts "Testing skills functionality..."

    # Find a user with a resume
    user = User.first
    if user.nil?
      puts "❌ No users found in database"
      exit 1
    end

    resume = user.resume
    if resume.nil?
      puts "❌ No resume found for user #{user.email}"
      exit 1
    end

    puts "✅ Found resume for user: #{user.email}"
    puts "   Current skills: #{resume.skills.map(&:name).join(', ')}"

    # Test creating a skill
    puts "\n📝 Testing skill creation..."
    skill = resume.skills.new(name: "Test Skill #{Time.current.to_i}")

    if skill.save
      puts "✅ Skill created successfully: #{skill.name}"
    else
      puts "❌ Skill creation failed: #{skill.errors.full_messages}"
    end

    # Test nested attributes
    puts "\n🔄 Testing nested attributes..."
    params = {
      resume: {
        skills_attributes: [
          { name: "Nested Skill 1" },
          { name: "Nested Skill 2" }
        ]
      }
    }

    if resume.update(params[:resume])
      puts "✅ Nested attributes update successful"
      puts "   Skills after update: #{resume.skills.reload.map(&:name).join(', ')}"
    else
      puts "❌ Nested attributes update failed: #{resume.errors.full_messages}"
    end

    # Test form parameters structure
    puts "\n📋 Testing form parameters structure..."
    form_params = {
      "resume" => {
        "skills_attributes" => {
          "0" => { "name" => "Form Skill 1", "_destroy" => "0" },
          "1" => { "name" => "Form Skill 2", "_destroy" => "0" }
        }
      }
    }

    if resume.update(form_params["resume"])
      puts "✅ Form parameters update successful"
      puts "   Skills after form update: #{resume.skills.reload.map(&:name).join(', ')}"
    else
      puts "❌ Form parameters update failed: #{resume.errors.full_messages}"
    end

    puts "\n✅ Skills functionality test completed"
  end

  desc "Clean up test skills"
  task cleanup: :environment do
    puts "Cleaning up test skills..."

    # Remove skills with "Test" in the name
    test_skills = Skill.where("name LIKE ?", "%Test%")
    count = test_skills.count

    if count > 0
      test_skills.destroy_all
      puts "✅ Removed #{count} test skills"
    else
      puts "ℹ️  No test skills found to remove"
    end
  end
end
