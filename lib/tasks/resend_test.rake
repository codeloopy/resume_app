namespace :resend do
  desc "Test Resend configuration and send a test email"
  task test: :environment do
    puts "Testing Resend configuration..."

    # Check if we're in production
    unless Rails.env.production?
      puts "⚠️  Warning: This test should be run in production environment"
      puts "   Current environment: #{Rails.env}"
    end

    # Check credentials
    resend_credentials = Rails.application.credentials.resend
    if resend_credentials&.dig(:api_key)
      puts "✅ Resend API key found"
      puts "   API Key: #{resend_credentials[:api_key][0..10]}..."
    else
      puts "❌ No Resend API key found in credentials"
      exit 1
    end

    # Test Resend configuration
    begin
      require "resend"
      Resend.api_key = resend_credentials[:api_key]

      puts "✅ Resend gem loaded and API key set"

      # Test sending an email
      puts "📧 Attempting to send test email..."

      test_result = Resend::Emails.send({
        from: "noreply@freeresumebuilderapp.com",
        to: "test@example.com",
        subject: "Resend Configuration Test",
        html: "<p>This is a test email to verify Resend configuration.</p>"
      })

      puts "✅ Test email sent successfully!"
      puts "   Email ID: #{test_result[:id]}"

    rescue Resend::Error => e
      puts "❌ Resend Error: #{e.message}"
      puts "   Error Class: #{e.class}"

      if e.respond_to?(:response) && e.response
        puts "   Response: #{e.response.inspect}"
      end

      if e.respond_to?(:code) && e.code
        puts "   Error Code: #{e.code}"
      end

      puts "\n🔍 Common Resend Issues:"
      puts "   1. Domain not verified in Resend dashboard"
      puts "   2. Sender email not verified"
      puts "   3. Invalid API key"
      puts "   4. Rate limiting"

    rescue => e
      puts "❌ Unexpected Error: #{e.message}"
      puts "   Error Class: #{e.class}"
      puts "   Backtrace: #{e.backtrace.first(5).join("\n")}"
    end
  end

  desc "Check Resend domain verification status"
  task check_domain: :environment do
    puts "Checking Resend domain verification..."

    resend_credentials = Rails.application.credentials.resend
    if resend_credentials&.dig(:api_key)
      begin
        require "resend"
        Resend.api_key = resend_credentials[:api_key]

        # Note: This would require the Resend API to have domain listing capability
        # For now, we'll just provide guidance
        puts "📋 To check domain verification:"
        puts "   1. Go to https://resend.com/domains"
        puts "   2. Verify that 'freeresumebuilderapp.com' is added and verified"
        puts "   3. Check that DNS records are properly configured"

      rescue => e
        puts "❌ Error checking domain: #{e.message}"
      end
    else
      puts "❌ No Resend API key found"
    end
  end
end
