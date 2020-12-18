FROM ruby:2.6-buster

# Create our working directory
RUN mkdir /rune.rb

# Set the working directory to /rune.rb
WORKDIR /rune.rb

# . Defines the current working directory
COPY Gemfile .

# Install our dependancies
RUN bundle install

# Copy our files over.
COPY /deployment .

# Expose the port which the endpoint will listen
EXPOSE 43594

CMD ["ruby", "bootstrap.rb"]

