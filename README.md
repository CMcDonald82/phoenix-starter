# phoenix-starter
A starter Elixir/Phoenix project that can be used as a base to build off of

NOTE: This project can be run inside a Docker container for development (in which case it includes a Postgres database container), for production builds (the container has the same OS (Ubuntu 16.04) as the target server to deploy to so the build can use distillery/edeliver to build a release and deploy it to the server), and for tests.


## Useful Commands

To run a bash shell into the container:
```
docker run -it phoenixstarter_phoenix /bin/bash
```

To run inside a Docker container, run all commands as the following:

```
docker-compose [-f docker-compose.<dev|build|test>.yml ...] <service> 
```


## Setup

NOTE: The containers in steps 3.a and 3.b MUST be built before going further since some of the following steps depend on them


1. Clone the repo into a new project directory:
```
git clone https://github.com/CMcDonald82/phoenix-starter.git phoenix_starter
```

2. Add a public key to the project's top-level directory (this key will be used to SSH into the Docker container for building releases)
```
cp <path-to-ssh-pubkey-on-local-machine> .
```

3. a.) Build the base Docker container (must be named phoenix_base since the docker-compose files depend on it). This container will be used for local development/debugging and running tests (locally and via Travis)
```
docker build --target base -t phoenix-base:latest .
```

3. b.) Build the build Docker container (must be named phoenix_build since the docker-compose files depend on it). This container will be used to build releases in
```
docker build -t phoenix-build:latest .
```

4. Get mix deps
```
docker-compose run phoenix mix deps.get
```

* Create the database
```
docker-compose run phoenix mix ecto.create
```

* Install frontend dependencies (via yarn) - these will go in ./assets/node_modules
```
docker-compose run -w /app/assets phoenix yarn install
```


To build a release:
* Set the environment variable PHOENIX_STARTER_PROD_HOST to be the domain name you have set up for the server

* Run the container that the build will be performed in
```
docker-compose -f docker-compose.yml -f docker-compose.build.yml up
```

* Add node_modules to local git repo (since these will be needed by edeliver to build the release within the Docker container)
```
git add .
git commit -am 'add /assets/node_modules to local git repo'
```

* Build the release
```
mix edeliver build release --verbose
```


## Notes/Links

* Docker
  - [Install Erlang/Elixir](https://elixir-lang.org/install.html#unix-and-unix-like)
  - [Install Node.js](https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions)
  - [Install Yarn](https://yarnpkg.com/lang/en/docs/install/#linux-tab)
  - [Install Phoenix (latest)](https://hexdocs.pm/phoenix/installation.html)
  - [Setup SSHd](https://docs.docker.com/engine/examples/running_ssh_service/)