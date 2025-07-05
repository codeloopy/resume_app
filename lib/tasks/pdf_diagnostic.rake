namespace :pdf do
  desc "Diagnose PDF generation configuration"
  task diagnose: :environment do
    puts "=== PDF Generation Diagnostic ==="
    puts "Environment: #{Rails.env}"
    puts "Rails version: #{Rails.version}"
    puts "Grover version: #{Gem.loaded_specs['grover']&.version}"

    puts "\n=== Chromium/Chrome Detection ==="

    # Check common paths
    possible_paths = [
      "/usr/bin/chromium",
      "/usr/bin/chromium-browser",
      "/usr/bin/google-chrome",
      "/usr/bin/google-chrome-stable",
      "/snap/bin/chromium",
      "/opt/google/chrome/chrome"
    ]

    puts "Checking common paths:"
    possible_paths.each do |path|
      exists = File.exist?(path)
      puts "  #{path}: #{exists ? '✅ EXISTS' : '❌ NOT FOUND'}"
    end

    # Try which command
    puts "\nTrying 'which' command:"
    begin
      require "open3"

      stdout, stderr, status = Open3.capture3("which chromium")
      if status.success?
        puts "  chromium: #{stdout.strip} ✅"
      else
        puts "  chromium: Not found ❌"
      end

      stdout, stderr, status = Open3.capture3("which google-chrome")
      if status.success?
        puts "  google-chrome: #{stdout.strip} ✅"
      else
        puts "  google-chrome: Not found ❌"
      end

      stdout, stderr, status = Open3.capture3("which chrome")
      if status.success?
        puts "  chrome: #{stdout.strip} ✅"
      else
        puts "  chrome: Not found ❌"
      end
    rescue => e
      puts "  Error running 'which' command: #{e.message}"
    end

    puts "\n=== Grover Configuration ==="
    puts "Executable path: #{Grover.configuration.options[:executable_path] || 'Not set'}"
    puts "Format: #{Grover.configuration.options[:format]}"
    puts "Args count: #{Grover.configuration.options[:args]&.length || 0}"

    puts "\n=== Template Rendering Test ==="
    begin
      # Create a test resume with minimal data
      user = User.first || User.create!(
        email: "test@example.com",
        password: "password123",
        first_name: "Test",
        last_name: "User"
      )

      resume = user.resume || Resume.create!(
        user: user,
        title: "Test Resume",
        pdf_template: "modern"
      )

      # Test rendering the modern template
      puts "Testing modern template rendering..."
      modern_html = ApplicationController.renderer.render(
        template: "resumes/public_pdf_modern",
        layout: "pdf",
        formats: [ :html ],
        locals: { resume: resume }
      )
      puts "✅ Modern template rendered successfully (#{modern_html.length} characters)"

      # Test rendering the classic template
      puts "Testing classic template rendering..."
      classic_html = ApplicationController.renderer.render(
        template: "resumes/public_pdf_classic",
        layout: "pdf",
        formats: [ :html ],
        locals: { resume: resume }
      )
      puts "✅ Classic template rendered successfully (#{classic_html.length} characters)"

      # Check for external dependencies
      external_deps = []
      [ modern_html, classic_html ].each do |html|
        if html.include?("http://") || html.include?("https://")
          external_deps << "External URLs found"
        end
        if html.include?("cdn.jsdelivr.net")
          external_deps << "CDN resources found"
        end
      end

      if external_deps.empty?
        puts "✅ No external dependencies detected"
      else
        puts "⚠️  External dependencies detected: #{external_deps.uniq.join(', ')}"
      end

    rescue => e
      puts "❌ Template rendering failed:"
      puts "  #{e.class}: #{e.message}"
      puts "  Backtrace:"
      e.backtrace.first(3).each { |line| puts "    #{line}" }
    end

    puts "\n=== Test PDF Generation ==="
    begin
      # Create a simple HTML for testing
      html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>Test PDF</title>
          <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            h1 { color: #333; }
          </style>
        </head>
        <body>
          <h1>PDF Generation Test</h1>
          <p>This is a test PDF generated at #{Time.current}</p>
          <p>Environment: #{Rails.env}</p>
        </body>
        </html>
      HTML

      puts "Attempting to generate PDF with Grover..."
      grover = Grover.new(html)
      pdf = grover.to_pdf

      if pdf && pdf.length > 0
        puts "✅ Grover PDF generation successful!"
        puts "PDF size: #{pdf.length} bytes"

        # Save test PDF
        test_file = Rails.root.join("tmp", "test_pdf_diagnostic.pdf")
        File.binwrite(test_file, pdf)
        puts "Test PDF saved to: #{test_file}"
      else
        puts "❌ Grover PDF generation failed - empty result"
      end

    rescue => e
      puts "❌ Grover PDF generation failed with error:"
      puts "  #{e.class}: #{e.message}"
      puts "  Backtrace:"
      e.backtrace.first(5).each { |line| puts "    #{line}" }
    end

    puts "\n=== Test Prawn PDF Generation ==="
    begin
      # Create a test resume for Prawn
      user = User.first || User.create!(
        email: "test@example.com",
        password: "password123",
        first_name: "Test",
        last_name: "User"
      )

      resume = user.resume || Resume.create!(
        user: user,
        title: "Test Resume",
        pdf_template: "modern"
      )

      puts "Attempting to generate PDF with Prawn..."
      require "prawn"
      require "prawn/table"

      pdf_data = Prawn::Document.new do |pdf|
        pdf.font "Helvetica"
        pdf.font_size 24
        pdf.text "Test PDF Generated with Prawn", style: :bold
        pdf.move_down 20
        pdf.font_size 12
        pdf.text "Generated at: #{Time.current}"
        pdf.text "Environment: #{Rails.env}"
        pdf.text "Resume: #{resume.title}"
      end.render

      if pdf_data && pdf_data.length > 0
        puts "✅ Prawn PDF generation successful!"
        puts "PDF size: #{pdf_data.length} bytes"

        # Save test PDF
        test_file = Rails.root.join("tmp", "test_prawn_diagnostic.pdf")
        File.binwrite(test_file, pdf_data)
        puts "Prawn test PDF saved to: #{test_file}"
      else
        puts "❌ Prawn PDF generation failed - empty result"
      end

    rescue => e
      puts "❌ Prawn PDF generation failed with error:"
      puts "  #{e.class}: #{e.message}"
      puts "  Backtrace:"
      e.backtrace.first(5).each { |line| puts "    #{line}" }
    end

            puts "\n=== Test Unified Template System ==="
    begin
      # Test modern template
      puts "Testing modern template..."
      modern_pdf = ResumesController.new.send(:generate_prawn_pdf, resume, "modern")
      puts "✅ Modern template: #{modern_pdf.length} bytes"

      # Test classic template
      puts "Testing classic template..."
      classic_pdf = ResumesController.new.send(:generate_prawn_pdf, resume, "classic")
      puts "✅ Classic template: #{classic_pdf.length} bytes"

      # Save both for comparison
      File.binwrite(Rails.root.join("tmp", "test_modern_prawn.pdf"), modern_pdf)
      File.binwrite(Rails.root.join("tmp", "test_classic_prawn.pdf"), classic_pdf)
      puts "Both templates saved to tmp/ for comparison"

      # Test template data generation
      puts "Testing template data generation..."
      modern_data = ResumesController.new.send(:get_template_data, resume, "modern")
      classic_data = ResumesController.new.send(:get_template_data, resume, "classic")
      puts "✅ Modern data: #{modern_data[:sections].keys.join(', ')}"
      puts "✅ Classic data: #{classic_data[:sections].keys.join(', ')}"

    rescue => e
      puts "❌ Template testing failed with error:"
      puts "  #{e.class}: #{e.message}"
      puts "  Backtrace:"
      e.backtrace.first(3).each { |line| puts "    #{line}" }
    end

    puts "\n=== System Information ==="
    puts "Platform: #{RUBY_PLATFORM}"
    puts "Ruby version: #{RUBY_VERSION}"
    puts "Working directory: #{Dir.pwd}"

    puts "\n=== Recommendations ==="
    if Rails.env.production?
      puts "1. Ensure Chromium/Chrome is installed in production"
      puts "2. Check if the executable path is correct"
      puts "3. Verify file permissions for the Chromium executable"
      puts "4. Check production logs for detailed error messages"
    else
      puts "1. Install Chromium/Chrome if not already installed"
      puts "2. Test PDF generation locally before deploying"
    end
  end
end
