# phoenix-starter
A starter Elixir/Phoenix project that can be used as a base to build off of

NOTE: This project can be run inside a Docker container for development (in which case it includes a Postgres database container), for production builds (the container has the same OS (Ubuntu 16.04) as the target server to deploy to so the build can use distillery/edeliver to build a release and deploy it to the server), and for tests.

This project includes the following:
* Erlang/Elixir (latest)
* Phoenix (latest)
* Node.js (v 8.x)
* React/Redux
* Webpack
* PostgreSQL 10

NOTE: This is a work in progress so it is not ready to use yet. When it is, you are welcome to (and should!) use this 
project as a base to get a new Phoenix/React project going!

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


1. Clone the repo into a new project directory and cd into it:
```
git clone https://github.com/CMcDonald82/phoenix-starter.git <new_project_dir> && cd <new_project_dir>
```

2. Add a public key to the project's top-level directory (this key will be used to SSH into the Docker container for building releases)
```
cp <path-to-ssh-pubkey-on-local-machine> ./ssh_key.pub
```

3. a.) Build the base Docker container (must be named phoenix_base since the docker-compose files depend on it). This container will be used for local development/debugging and running tests (locally and via Travis)
```
docker build --target base -t phoenix-base:latest .
```

3. b.) Build the build Docker container (must be named phoenix_build since the docker-compose files depend on it). This container will be used to build releases in
```
docker build -t phoenix-build:latest .
```

4. Set local environment variables: 
  - PHOENIX_OTP_APP_NAME: This is the new name you're giving your project. This variable will be used by the Edeliver config and the custom vm.args.prod file. It should be the [snake_case](https://en.wikipedia.org/wiki/Snake_case) version of the name you want to give your new app (for example, if you're calling your new project ExampleApp, you would set this env var to example_app). This same variable also needs to be set to the same value on the server you are deploying to. 
  - PHOENIX_STARTER_PROD_HOST/PHOENIX_STARTER_STG_HOST: These variables should be set to either the domain name or IP address (if you haven't associated a domain name with your server yet) of your production and staging servers, respectively. If you do not have a production or a staging server set up, you do not need to set these variables (for example, if you only have a production server to deploy to, you do not need to set the variable for the staging server). However, since these variables are used for deployment, you will need to set them if you want to deploy to those servers.
```
export REPLACE_OS_VARS=true
export PHOENIX_OTP_APP_NAME="<newname>"
export PHOENIX_STARTER_PROD_HOST="<domain name or IP of prod server>"
export PHOENIX_STARTER_STG_HOST="<domain name or IP of stg server>"
```

## NOTE: Maybe add something here about optionally configuring the :git_reinit config var in config/setup.exs

5. Get mix deps 
```
docker-compose run phoenix mix deps.get
```

6. Install frontend dependencies (via Yarn) 
```
docker-compose run -w /app/assets phoenix yarn install
```

7. Run the mix setup task to rename the app, create a new README, and initialize a fresh git repo for the new project
```
docker-compose run phoenix mix setup PhoenixStarter <NewName> phoenix_starter <new_name>
```

8. Create and migrate the database 
```
docker-compose run phoenix mix ecto.create
docker-compose run phoenix mix ecto.migrate
```


To build a release:
* Set the environment variable PHOENIX_STARTER_PROD_HOST to be the domain name you have set up for the server

* Run the container that the build will be performed in
```
docker-compose -f docker-compose.yml -f docker-compose.build.yml up
```

* Run mix deps.get locally (outside the Docker container). This is necessary since we will be running the Edeliver commands outside a Docker container.
```
mix deps.get
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