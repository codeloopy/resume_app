ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Load .env before anything else (must run before bootsnap/rails so ENV is set for initializers)
begin
  require "dotenv"
  env_path = File.expand_path("../.env", __dir__)
  Dotenv.load(env_path) if File.exist?(env_path)
rescue LoadError
  # dotenv not available in production
end

require "bootsnap/setup" # Speed up boot time by caching expensive operations.
