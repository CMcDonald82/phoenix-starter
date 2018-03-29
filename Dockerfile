FROM ubuntu:16.04 AS base

# Avoid error messages from apt when building the image
ARG DEBIAN_FRONTEND=noninteractive

# Install apt-utils (for package configuration)
RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends apt-utils

# Install curl - necessary for some of the packages we will be installing
RUN \
  apt-get update && \
  apt-get install -y wget curl

# Install Erlang/Elixir (see Notes/Links section in README)
RUN \
  wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
  dpkg -i erlang-solutions_1.0_all.deb && \
  apt-get update && \
  apt-get install -y esl-erlang elixir build-essential openssh-server git inotify-tools locales

# Install Node.js (see Notes/Links section in README)
RUN \
  apt-get update && \
  curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get install -y nodejs

# Install Yarn (we will be using this instead of NPM) (see Notes/Links section in README) 
RUN \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - 
RUN \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN \
  apt-get update && \
  apt-get install yarn 

# Setup locales for Elixir (requires UTF-8)
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN update-locale LANG=$LANG

# Run mix commands (install Hex, Rebar, etc.)
RUN mix local.hex --force
RUN mix local.rebar --force

# Install latest Phoenix (latest) (see Notes/Links section in README)
RUN mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez --force

# Create app folder
RUN mkdir /app
COPY . /app
WORKDIR /app


FROM base
COPY --from=base /app .

# Setup SSHd service for use with Edeliver
# Required for setting up SSHd - (see Notes/Links section in README) 
RUN mkdir /var/run/sshd

# Create 'builder' user for building releases with Distillery & Edeliver
RUN useradd --system --shell=/bin/bash --create-home builder
# USER builder

# Configure the 'builder' user for public key authentication
RUN mkdir /home/builder/.ssh/ && chmod 700 /home/builder/.ssh/
COPY ./ssh_key.pub /home/builder/.ssh/authorized_keys
RUN chown -R builder /home/builder/
RUN chgrp -R builder /home/builder/
RUN chmod 700 /home/builder/.ssh/
RUN chmod 644 /home/builder/.ssh/authorized_keys

# Configure public keys for sshd
RUN echo "AuthorizedKeysFile  %h/.ssh/authorized_keys" >> /etc/ssh/sshd_config

