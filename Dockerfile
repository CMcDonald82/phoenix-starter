FROM ubuntu:16.04 AS base

# TODO: Move the website links to README.md once we get this Dockerfile working

# Avoid error messages from apt when building the image
ARG DEBIAN_FRONTEND=noninteractive

# Install curl - necessary for some of the packages we will be installing
RUN \
  apt-get update && \
  apt-get install -y wget curl

# Install apt-utils (for package configuration)
RUN \
  apt-get update && \
  apt-get install -y apt-utils

# Install Erlang/Elixir (see https://elixir-lang.org/install.html#unix-and-unix-like)
RUN \
  wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
  dpkg -i erlang-solutions_1.0_all.deb && \
  apt-get update && \
  apt-get install -y esl-erlang elixir build-essential openssh-server git inotify-tools locales

# Setup locales for Elixir (requires UTF-8)
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN update-locale LANG=$LANG

# NOTE: This is probably not needed if we are transferring environment variables to prod via Ansible role
# Copy config/prod.secret.exs into /home/builder/ directory so it is available to edeliver
# RUN mkdir -p /home/builder/config
# COPY config/prod.secret.exs /home/builder/config/prod.secret.exs

# Run mix commands (install Hex, Rebar, etc.)
RUN mix local.hex --force
RUN mix local.rebar --force

# Install latest Phoenix (see https://hexdocs.pm/phoenix/installation.html)
RUN mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez --force

# Install Node.js (see https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions)
RUN \
  apt-get update && \
  curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get install -y nodejs

# Install Yarn (we will be using this instead of NPM) (see https://yarnpkg.com/lang/en/docs/install/#linux-tab)
RUN \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - 
RUN \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN \
  apt-get update && \
  apt-get install yarn 

# Create app folder
RUN mkdir /app
COPY . /app
WORKDIR /app

FROM base
COPY --from=base /app .

# Setup SSHd service for use with edeliver
# Required for setting up SSHd - (see https://docs.docker.com/engine/examples/running_ssh_service/)
RUN mkdir /var/run/sshd

# Create 'builder' user for building releases with Distillery & Edeliver
RUN useradd --system --shell=/bin/bash --create-home builder

# Configure the 'builder' user for public key authentication
RUN mkdir /home/builder/.ssh/ && chmod 700 /home/builder/.ssh/
COPY ./ssh_key.pub /home/builder/.ssh/authorized_keys
RUN chown -R builder /home/builder/
RUN chgrp -R builder /home/builder/
RUN chmod 700 /home/builder/.ssh/
RUN chmod 644 /home/builder/.ssh/authorized_keys

# Configure public keys for sshd
RUN echo "AuthorizedKeysFile  %h/.ssh/authorized_keys" >> /etc/ssh/sshd_config

# These are for SSH - see if this is compatible or whether these need to be in (a possibly separate) docker-compose.yml fiel
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]


# NOTE: Put other mix commands (ecto.migrate, build, deps.get, yarn install, etc.) in shell scripts