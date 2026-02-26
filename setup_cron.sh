#!/bin/bash

# Script to set up cron job for guest user cleanup (24-hour retention)
# NOTE: If you deploy to Fly.io, cron runs automatically via Supercronic (see crontab + fly.toml).
#       Just run: fly scale count cron=1 app=1
# This script is for local development or self-hosted servers only.
echo "Setting up cron job for guest user cleanup..."

# Get the current directory
CURRENT_DIR=$(pwd)

# Run hourly to clean up guests older than 24 hours
CRON_JOB="0 * * * * cd $CURRENT_DIR && bundle exec rails guest:cleanup"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "guest:cleanup"; then
    echo "Cron job already exists!"
    crontab -l | grep "guest:cleanup"
else
    # Add the cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added successfully!"
    echo "The job will run hourly and clean up guest users older than 24 hours"
fi

echo ""
echo "Current crontab:"
crontab -l 2>/dev/null || echo "No crontab entries found"

echo ""
echo "To manually test the cleanup, run:"
echo "bundle exec rails guest:cleanup"
