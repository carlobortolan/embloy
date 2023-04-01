# Use an official Ruby runtime as a parent image
FROM ruby:2.7.5

# Set the working directory in the container to /app
WORKDIR /app

# Copy the Gemfile and Gemfile.lock from the app root directory into the container
COPY Gemfile Gemfile.lock ./

# Install any needed packages specified in the Gemfile
RUN bundle install

# Copy the rest of the application code into the container
COPY . .

# Set the default environment variables
ENV RAILS_ENV=deployment \
    RACK_ENV=deployment \

# Precompile the assets
RUN bundle install; bundle exec rake assets:precompile; bundle exec rake assets:clean;

# Expose port 3000 from the container to the host
EXPOSE 3000

# Start the Rails server when the container starts
CMD ["rails", "server", "-b", "0.0.0.0"]
