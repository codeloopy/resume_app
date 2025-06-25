namespace :pdf do
  desc "Test PDF generation functionality"
  task test: :environment do
    puts "Testing PDF generation..."

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
    puts "   Resume slug: #{resume.slug}"

    # Test HTML rendering first
    puts "\n📄 Testing HTML rendering..."
    begin
      html = ApplicationController.renderer.render(
        template: "resumes/public_pdf",
        layout: "pdf",
        formats: [ :html ],
        locals: { resume: resume }
      )
      puts "✅ HTML rendering successful"
      puts "   HTML length: #{html.length} characters"
    rescue => e
      puts "❌ HTML rendering failed: #{e.message}"
      puts "   Error class: #{e.class}"
      exit 1
    end

    # Test Grover configuration
    puts "\n⚙️  Testing Grover configuration..."
    begin
      grover_options = {
        format: "A4",
        margin: {
          top: "0.5in",
          bottom: "0.5in",
          left: "0.5in",
          right: "0.5in"
        },
        prefer_css_page_size: true,
        emulate_media: "screen",
        args: [
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--disable-dev-shm-usage",
          "--disable-accelerated-2d-canvas",
          "--no-first-run",
          "--no-zygote",
          "--disable-gpu"
        ]
      }

      grover = Grover.new(html, grover_options)
      puts "✅ Grover instance created successfully"

      # Test PDF generation
      puts "\n📄 Testing PDF generation..."
      Timeout.timeout(30) do
        pdf_data = grover.to_pdf
        puts "✅ PDF generation successful"
        puts "   PDF size: #{pdf_data.length} bytes"

        # Save test PDF
        test_file = Rails.root.join("tmp", "test_resume.pdf")
        File.write(test_file, pdf_data)
        puts "   Test PDF saved to: #{test_file}"
      end

    rescue Grover::JavaScript::UnknownError => e
      puts "❌ Grover JavaScript error: #{e.message}"
      puts "   This might indicate missing Chrome dependencies"

    rescue Timeout::Error => e
      puts "❌ PDF generation timed out after 30 seconds"
      puts "   This might indicate Chrome is not responding"

    rescue => e
      puts "❌ PDF generation failed: #{e.message}"
      puts "   Error class: #{e.class}"
      puts "   Error backtrace: #{e.backtrace.first(3).join("\n")}"
    end

    puts "\n✅ PDF generation test completed"
  end

  desc "Test PDF generation with different content"
  task test_content: :environment do
    puts "Testing PDF generation with different content..."

    user = User.first
    resume = user.resume

    # Test with minimal content
    puts "\n📄 Testing with minimal content..."
    minimal_html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Test PDF</title>
        <style>
          body { font-family: Arial, sans-serif; font-size: 12px; }
        </style>
      </head>
      <body>
        <h1>Test Resume</h1>
        <p>This is a test PDF generation.</p>
      </body>
      </html>
    HTML

    begin
      grover = Grover.new(minimal_html, format: "A4")
      pdf_data = grover.to_pdf
      puts "✅ Minimal content PDF generation successful"
      puts "   PDF size: #{pdf_data.length} bytes"
    rescue => e
      puts "❌ Minimal content PDF generation failed: #{e.message}"
    end

    # Test with external CSS
    puts "\n📄 Testing with external CSS..."
    external_css_html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Test PDF with External CSS</title>
        <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
      </head>
      <body class="bg-white p-8">
        <h1 class="text-2xl font-bold text-gray-800">Test Resume</h1>
        <p class="text-gray-600">This is a test PDF with external CSS.</p>
      </body>
      </html>
    HTML

    begin
      grover = Grover.new(external_css_html, format: "A4")
      pdf_data = grover.to_pdf
      puts "✅ External CSS PDF generation successful"
      puts "   PDF size: #{pdf_data.length} bytes"
    rescue => e
      puts "❌ External CSS PDF generation failed: #{e.message}"
    end

    puts "\n✅ Content testing completed"
  end

  desc "Clean up test files"
  task cleanup: :environment do
    puts "Cleaning up test files..."

    test_file = Rails.root.join("tmp", "test_resume.pdf")
    if File.exist?(test_file)
      File.delete(test_file)
      puts "✅ Removed test PDF file"
    else
      puts "ℹ️  No test PDF file found"
    end
  end
end
