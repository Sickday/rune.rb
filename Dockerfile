FROM ruby:2.7.4-buster

# Hi :)
MAINTAINER Patrick W., Sickday@pm.me

# Working Directory
RUN mkdir /rune.rb

# Set it as such
WORKDIR /rune.rb

# Copy Gemfile for deps
COPY Gemfile .

# Install deps
RUN bundle install

# Move release files to working dir
COPY /release .

# Expose the game port
EXPOSE 43594

# Expose the cache port
EXPOSE 43595

# Light that shit up yo
CMD ["rake", "rune_rb:live:run"]
