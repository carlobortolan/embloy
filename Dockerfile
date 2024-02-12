# Base image
FROM ruby:3.2.2

# Set the working directory inside the container
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
RUN bundle exec rake assets:precompile

# Expose port 3000
EXPOSE 3000

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]