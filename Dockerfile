# Base image
FROM ruby:3.2.2

# startTODO: WORKAROUND FOR MALFORMED MAWSITSIT GEM COMPILATION
# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev curl llvm-dev libclang-dev clang

# Install Rust (for building gems with native extensions that use Rust)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Verify installation and locate libclang
RUN ldconfig -p | grep libclang

# Find and set the correct LIBCLANG_PATH
RUN echo "Verifying possible libclang paths" && \
    ldconfig -p | grep libclang && \
    if [ -d "/usr/lib/llvm-10/lib" ]; then \
        echo "Setting LIBCLANG_PATH to /usr/lib/llvm-10/lib"; \
        export LIBCLANG_PATH="/usr/lib/llvm-10/lib"; \
    elif [ -d "/usr/lib/x86_64-linux-gnu" ]; then \
        echo "Setting LIBCLANG_PATH to /usr/lib/x86_64-linux-gnu"; \
        export LIBCLANG_PATH="/usr/lib/x86_64-linux-gnu"; \
    else \
        echo "Could not find libclang path"; \
        exit 1; \
    fi

# endTODO: WORKAROUND FOR MALFORMED MAWSITSIT GEM COMPILATION

WORKDIR /app

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential \
                       libpq-dev \
                       nodejs \
                       npm

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile Gemfile.lock ./

# Install gems
RUN gem install bundler:2.2.23 && \
    bundle install

# Copy the application code into the container
COPY . .

# Set environment variables
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

# Precompile assets
# RUN bundle exec rake assets:precompile

# Expose port 3000
EXPOSE 3000

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
