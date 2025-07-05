namespace :debug do
  desc "Debug PDF generation issues"
  task pdf: :environment do
    puts "=== PDF Generation Debug ==="

    # Check Grover configuration
    puts "\n📋 Grover Configuration:"
    puts "Executable path: #{Grover.configuration.options[:executable_path]}"
    puts "Format: #{Grover.configuration.options[:format]}"
    puts "Args count: #{Grover.configuration.options[:args].length}"

    # Check if Chromium executable exists
    puts "\n🔍 Chromium Executable Check:"
    executable_path = Grover.configuration.options[:executable_path]
    if executable_path
      if File.exist?(executable_path)
        puts "✅ Chromium found at: #{executable_path}"
        puts "   File size: #{File.size(executable_path)} bytes"
        puts "   Executable: #{File.executable?(executable_path)}"
      else
        puts "❌ Chromium not found at: #{executable_path}"
      end
    else
      puts "❌ No executable path configured"
    end

    # Try to find Chromium using which
    puts "\n🔍 System Chromium Check:"
    begin
      require "open3"
      stdout, stderr, status = Open3.capture3("which chromium")
      if status.success?
        puts "✅ System chromium found: #{stdout.strip}"
      else
        puts "❌ System chromium not found"
      end

      stdout, stderr, status = Open3.capture3("which google-chrome")
      if status.success?
        puts "✅ System google-chrome found: #{stdout.strip}"
      else
        puts "❌ System google-chrome not found"
      end
    rescue => e
      puts "❌ Error checking system: #{e.message}"
    end

    # Test simple PDF generation
    puts "\n🧪 Testing PDF Generation:"
    begin
      html = "<html><body><h1>Test</h1></body></html>"
      grover = Grover.new(html)
      pdf_data = grover.to_pdf
      puts "✅ PDF generation successful"
      puts "   PDF size: #{pdf_data.length} bytes"
    rescue => e
      puts "❌ PDF generation failed: #{e.message}"
      puts "   Error class: #{e.class}"
      puts "   Backtrace: #{e.backtrace.first(3).join("\n")}"
    end

    # Check environment
    puts "\n🌍 Environment:"
    puts "Rails env: #{Rails.env}"
    puts "Ruby version: #{RUBY_VERSION}"
    puts "Grover version: #{Grover::VERSION}"

    puts "\n✅ PDF debug completed"
  end
end
