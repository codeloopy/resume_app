#!/bin/bash

# Script to set up cron job for guest user cleanup
echo "Setting up cron job for guest user cleanup..."

# Get the current directory
CURRENT_DIR=$(pwd)

# Create the cron job entry
CRON_JOB="0 2 * * * cd $CURRENT_DIR && rails runner \"User.cleanup_old_guests\""

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "User.cleanup_old_guests"; then
    echo "Cron job already exists!"
    crontab -l | grep "User.cleanup_old_guests"
else
    # Add the cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added successfully!"
    echo "The job will run daily at 2 AM and clean up old guest users"
fi

echo ""
echo "Current crontab:"
crontab -l 2>/dev/null || echo "No crontab entries found"

echo ""
echo "To manually test the cleanup, run:"
echo "rails runner \"User.cleanup_old_guests\""
