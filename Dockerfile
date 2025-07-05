# syntax=docker/dockerfile:1
# check=error=true

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.1.2
FROM ruby:$RUBY_VERSION-slim AS base

LABEL fly_launch_runtime="rails"

# Rails app lives here
WORKDIR /rails

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler

# Install base packages needed to install nodejs and chrome
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl gnupg libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_ENV="production"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install Node.js using official NodeSource repository
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install packages needed to build gems and node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libffi-dev libpq-dev libyaml-dev pkg-config python-is-python3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install yarn
ARG YARN_VERSION=1.22.19
RUN npm install -g yarn@$YARN_VERSION

# Build options
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD="true"

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install node modules
COPY .yarnrc package.json package-lock.json yarn.lock ./
COPY .yarn/releases/* .yarn/releases/
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# Final stage for app image
FROM base

# Install Node.js in the final stage as well
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install packages needed for deployment including Chromium and its dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    chromium \
    chromium-sandbox \
    imagemagick \
    libvips \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    libxss1 \
    libxtst6 \
    libayatana-appindicator3-1 \
    fonts-noto-color-emoji \
    fonts-noto-cjk && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Verify Chromium installation and set up symlinks
RUN which chromium || which chromium-browser || which google-chrome || (echo "No Chromium found" && exit 1) && \
    echo "Chromium installation verified"

# Set up Chromium for non-root user
RUN mkdir -p /home/rails/.cache/chromium && \
    chown -R 1000:1000 /home/rails/.cache && \
    mkdir -p /tmp/chromium && \
    chown -R 1000:1000 /tmp/chromium

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R 1000:1000 db log storage tmp

# Create a script to verify Chromium is working
RUN echo '#!/bin/bash\n\
echo "=== Chromium Verification ==="\n\
echo "Checking Chromium installation..."\n\
which chromium && echo "✅ chromium found" || echo "❌ chromium not found"\n\
which chromium-browser && echo "✅ chromium-browser found" || echo "❌ chromium-browser not found"\n\
which google-chrome && echo "✅ google-chrome found" || echo "❌ google-chrome not found"\n\
echo "Checking Chromium version..."\n\
chromium --version 2>/dev/null || chromium-browser --version 2>/dev/null || google-chrome --version 2>/dev/null || echo "❌ Could not get version"\n\
echo "Checking Chromium permissions..."\n\
ls -la /usr/bin/chromium* 2>/dev/null || echo "No chromium in /usr/bin"\n\
ls -la /usr/bin/google-chrome* 2>/dev/null || echo "No google-chrome in /usr/bin"\n\
echo "=== End Verification ==="\n\
' > /rails/bin/verify-chromium && chmod +x /rails/bin/verify-chromium

USER 1000:1000

# Deployment options
ENV GROVER_NO_SANDBOX="true" \
    PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium" \
    CHROME_BIN="/usr/bin/chromium" \
    CHROME_PATH="/usr/bin/chromium"

# Entrypoint sets up the container.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]
