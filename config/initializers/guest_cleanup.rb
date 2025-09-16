# Guest User Cleanup Configuration
# This initializer documents the recommended cleanup approach

# RECOMMENDED: Use the User.cleanup_old_guests class method
# This method is defined in app/models/user.rb and can be called from anywhere

# AUTOMATIC CLEANUP OPTIONS:

# 1. Cron Job (Recommended for production):
# Add this to your crontab: crontab -e
# 0 2 * * * cd /Users/pedro/Projects/Rails/resume_app && rails runner "User.cleanup_old_guests"

# 2. Background Job (Alternative approach):
# If using Sidekiq or similar, you can create a recurring job that calls User.cleanup_old_guests

# 3. Manual Cleanup:
# rails runner "User.cleanup_old_guests"
# rails runner "User.cleanup_old_guests(30)" # for 30 days

# The cleanup method automatically:
# - Removes guest users older than 7 days (configurable)
# - Deletes associated resumes and data
# - Logs cleanup activities
# - Returns count of cleaned users
