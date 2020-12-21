FROM ruby:2.6-buster

# Me :)
MAINTAINER Patrick W., sickday@pm.me

# Create our working directory
RUN mkdir /rune.rb

# Set the working directory to /rune.rb
WORKDIR /rune.rb

# . Defines the current working directory
COPY Gemfile .

# Install our dependancies
RUN bundle install

# Copy our deployment filesfiles over. This is temporary and will be replaced with `gem install`.
COPY /deployment .

# Expose the port which the endpoint will listen
EXPOSE 43594

# Light that shit up yo
CMD ["ruby", "bootstrap.rb"]

