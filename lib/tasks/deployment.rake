namespace :deployment do
  desc "Check deployment readiness"
  task check: :environment do
    puts "=== Deployment Readiness Check ==="

    # Check if all migrations are up to date
    puts "\n📊 Checking migrations..."
    begin
      pending_migrations = ActiveRecord::Base.connection.migration_context.needs_migration?
      if pending_migrations
        puts "❌ Pending migrations found"
        puts "Run 'bin/rails db:migrate' to apply pending migrations"
      else
        puts "✅ All migrations are up to date"
      end
    rescue => e
      puts "❌ Error checking migrations: #{e.message}"
    end

    # Check database connectivity
    puts "\n🔌 Checking database connectivity..."
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      puts "✅ Database connection successful"
    rescue => e
      puts "❌ Database connection failed: #{e.message}"
    end

    # Check if critical tables exist
    puts "\n📋 Checking critical tables..."
    tables = %w[users resumes experiences skills educations projects]
    tables.each do |table|
      if ActiveRecord::Base.connection.table_exists?(table)
        puts "✅ Table '#{table}' exists"
      else
        puts "❌ Table '#{table}' missing"
      end
    end

    # Check if critical columns exist
    puts "\n🔍 Checking critical columns..."
    critical_columns = {
      users: %w[email first_name last_name],
      resumes: %w[slug title pdf_template skills_title],
      experiences: %w[company_name title start_date],
      skills: %w[name],
      educations: %w[school field_of_study]
    }

    critical_columns.each do |table, columns|
      columns.each do |column|
        if ActiveRecord::Base.connection.column_exists?(table, column)
          puts "✅ Column '#{table}.#{column}' exists"
        else
          puts "❌ Column '#{table}.#{column}' missing"
        end
      end
    end

    puts "\n✅ Deployment readiness check completed"
  end

  desc "Fix common deployment issues"
  task fix: :environment do
    puts "=== Fixing Common Deployment Issues ==="

    # Ensure all tables have required columns
    puts "\n🔧 Ensuring required columns exist..."

    # Add slug column if missing
    unless ActiveRecord::Base.connection.column_exists?(:resumes, :slug)
      puts "Adding missing slug column to resumes..."
      ActiveRecord::Base.connection.add_column :resumes, :slug, :string
      ActiveRecord::Base.connection.add_index :resumes, :slug, unique: true
    end

    # Add other critical columns if missing
    critical_columns = {
      users: { location: :string },
      resumes: {
        title: :string,
        pdf_template: :string,
        skills_title: :string
      }
    }

    critical_columns.each do |table, columns|
      columns.each do |column, type|
        unless ActiveRecord::Base.connection.column_exists?(table, column)
          puts "Adding missing #{column} column to #{table}..."
          ActiveRecord::Base.connection.add_column table, column, type
        end
      end
    end

    puts "\n✅ Deployment fixes completed"
  end
end
