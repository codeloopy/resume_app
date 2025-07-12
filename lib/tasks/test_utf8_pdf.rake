namespace :pdf do
  desc "Test UTF-8 PDF generation with external fonts"
  task test_utf8: :environment do
    puts "=== Testing UTF-8 PDF Generation ==="

    # Find or create a test user
    user = User.first
    if user.nil?
      puts "Creating test user..."
      user = User.create!(
        email: "test@example.com",
        password: "password123",
        first_name: "Test",
        last_name: "User"
      )
    end

    resume = user.resume
    if resume.nil?
      puts "Creating test resume..."
      resume = Resume.create!(
        user: user,
        title: "Test Resume",
        pdf_template: "modern"
      )
    end

    puts "Testing with user: #{user.email}"
    puts "Resume: #{resume.title}"

    # Test content with various Unicode characters
    test_content = [
      "Regular text",
      "Text with accents: é, ñ, ü, ç",
      "Text with symbols: ©, ®, ™, €, £, ¥",
      "Text with arrows: →, ←, ↑, ↓",
      "Text with math: ±, ×, ÷, ≤, ≥",
      "Text with emojis: 🚀, 📧, 💻, 🎯 (should be removed)",
      "Text with Chinese: 你好世界 (should be removed)",
      "Text with Arabic: مرحبا بالعالم (should be removed)"
    ]

    puts "\nTest content:"
    test_content.each { |content| puts "  - #{content}" }

    begin
      puts "\nGenerating PDF with Prawn..."

      # Generate PDF using the controller method
      controller = ResumesController.new
      pdf_data = controller.send(:generate_prawn_pdf, resume, "modern")

      if pdf_data && pdf_data.length > 0
        puts "✅ PDF generation successful!"
        puts "PDF size: #{pdf_data.length} bytes"

        # Save test PDF
        test_file = Rails.root.join("tmp", "test_utf8_pdf.pdf")
        File.binwrite(test_file, pdf_data)
        puts "Test PDF saved to: #{test_file}"

        # Try to open the PDF to verify it's valid
        begin
          require "pdf-reader"
          reader = PDF::Reader.new(test_file)
          puts "✅ PDF is valid and readable"
          puts "Pages: #{reader.page_count}"
          puts "First page text length: #{reader.pages.first.text.length} characters"
        rescue => e
          puts "⚠️  PDF generated but couldn't be read: #{e.message}"
        end
      else
        puts "❌ PDF generation failed - empty result"
      end

    rescue => e
      puts "❌ PDF generation failed with error:"
      puts "  #{e.class}: #{e.message}"
      puts "  Backtrace:"
      e.backtrace.first(5).each { |line| puts "    #{line}" }
    end

    puts "\n=== Font Availability Check ==="
    controller = ResumesController.new
    controller.send(:log_font_availability)

    puts "\n=== Test completed ==="
  end
end
