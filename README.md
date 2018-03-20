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

4. Set environment variables locally: 
  - REPLACE_OS_VARS: This is necessary for environment variables that are written as "${VARIABLE}" to be expanded. Also needed locally since the PHOENIX_OTP_APP_NAME var in the edeliver config will not work if REPLACE_OS_VARS is not set to true.  
  - PHOENIX_OTP_APP_NAME: This is the new name you're giving your project. This variable will be used by the Edeliver config and the custom vm.args.prod file. It should be the [snake_case](https://en.wikipedia.org/wiki/Snake_case) version of the name you want to give your new app (for example, if you're calling your new project ExampleApp, you would set this env var to example_app). This same variable also needs to be set to the same value on the server you are deploying to. 
  - PHOENIX_STARTER_PROD_HOST/PHOENIX_STARTER_STG_HOST: These variables should be set to either the domain name or IP address (if you haven't associated a domain name with your server yet) of your production and staging servers, respectively. If you do not have a production or a staging server set up, you do not need to set these variables (for example, if you only have a production server to deploy to, you do not need to set the variable for the staging server). However, since these variables are used for deployment, you will need to set them if you want to deploy to those servers.
```
EXAMPLE:

export REPLACE_OS_VARS=true
export PHOENIX_OTP_APP_NAME="<new_name>"
export PHOENIX_STARTER_PROD_HOST="<domain name or IP of prod server>"
export PHOENIX_STARTER_STG_HOST="<domain name or IP of stg server>"
```

5. Set environment variables on remote host:
  NOTE: These variables can be set either manually or using a provisioning tool such as Ansible. Check out (and feel free to use, if you'd like) [this Ansible playbook](https://github.com/CMcDonald82/ansible-playbook-ubuntu-phoenix) for an example of how to set these variables (and how to setup the remote host for deploying a Phoenix app in general)
  - REPLACE_OS_VARS: This is necessary for environment variables that are written as "${VARIABLE}" to be expanded.
  - DB_NAME: The name of the production database. This can be whatever you want, but a database with this name must be created on the remote host (this can be done manually or via something like the Ansible playbook linked above).
  - DB_USERNAME: This is the username of the user that will be connecting to the prod database. This user should be created on the server along with the production database (this can be done manually or via something like the Ansible playbook linked above). 
  - DB_PASSWORD: The password for the user that will be connecting to the prod database. 
  - DB_HOSTNAME: The hostname of the server where the database will be. We can set this to localhost if we are running the database on the same host as the app.
  - SECRET_KEY_BASE: This is a token that is used by the Phoenix app. Generate one with the following command:
```
mix phoenix.gen.secret
```
  - DOMAIN_NAME: The domain name for the remote server (ex. example.com). You will need to have obtained, setup and configured this separately (purchase domain name and set it up to point to the server you will be deploying your app to.)See [this project](https://github.com/CMcDonald82/ansible-playbook-ubuntu-phoenix) for some instructions on how to do this.
  - PORT: The port that the Phoenix app will be running on. You can set this to 4000.
  - PHOENIX_OTP_APP_NAME: Set this to the same value you set it to locally (the snake_case version of the name you want to give your new app).
  - ERLANG_COOKIE: This cookie is necessary for distributed Erlang apps to communicate with each other (see section 13.7 Security in the [Erlang docs](http://erlang.org/doc/reference_manual/distributed.html). Since we are setting this value via a custom vm.args file (vm.args.prod), we do not need to worry about setting it via the rel/config.exs file so you can leave the 'set cookie: "ignore"' line in that file. This will prevent Distillery from displaying a warning that the cookie has not been set (which will be an error in a future version of Distillery). It's fine to do this since the cookie will actually be set on the remote host when the app is deployed and started as long as the ERLANG_COOKIE variable is set on the remote host. This project includes a mix task "erlang_cookie" which will generate a token that can be used as the value of this variable. The erlang cookie task will output the value to a file in this project called .erlang_cookie - you can then copy this value and set ERLANG_COOKIE on your remote host to this value. The .erlang_cookie file is ignored by git by default and can be deleted or regenerated/overwritten by running the erlang_cookie task again. Outputting the cookie to a file prevents the it from being output to the console or worse, checked into the git repo which could be a security risk. The task can be run as follows (inside a Docker container):
```
docker-compose run phoenix mix erlang_cookie
```

```
EXAMPLE:

export REPLACE_OS_VARS=true
export DB_NAME=phoenix_starter_prod
export DB_USERNAME=postgres
export DB_PASSWORD=my_secret_password
export DB_HOSTNAME=localhost
export SECRET_KEY_BASE=sjvwejoifjef09u3
export DOMAIN_NAME=example.com
export PORT=4000
export PHOENIX_OTP_APP_NAME="<new_name>"
export ERLANG_COOKIE=7B5FD1F101FBD4BBD6FB3F2BB11E72A62DCB9EDCAAFFCWHJJNKJNKMSIOJJ
```

## NOTE: Maybe add something here about optionally configuring the :git_reinit config var in config/setup.exs

6. Get mix deps 
```
docker-compose run phoenix mix deps.get
```

7. Install frontend dependencies (via Yarn) 
```
docker-compose run -w /app/assets phoenix yarn install
```

8. Run the mix setup task to rename the app, create a new README, and initialize a fresh git repo for the new project
```
docker-compose run phoenix mix setup PhoenixStarter <NewName> phoenix_starter <new_name>
```

9. Create and migrate the database 
```
docker-compose run phoenix mix ecto.create
docker-compose run phoenix mix ecto.migrate
```


To build a release:
* Make sure you've set the environment variable PHOENIX_STARTER_PROD_HOST to be the domain name you have set up for the server

* Run the container that the build will be performed in
```
docker-compose -f docker-compose.yml -f docker-compose.build.yml up
```

You may skip the 

* The first time you run the container, ssh into it before building the release. Do this from a different terminal window than the one the build container is running in. Type yes at the prompt Are you sure you want to continue connecting (yes/no)?
```
ssh builder@localhost
```

* If you get the following warning, you can remove the existing ssh key that's in the known_hosts file so it can be replaced with the new, updated one. This scenario can happen if you build the container, then delete it, then build it again. 
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```
Run the following command to remove the existing ssh key that's in the known_hosts file
```
ssh-keygen -R localhost
```

* Run mix deps.get locally (outside the Docker container). This is necessary since we will be running the Edeliver commands outside a Docker container.
```
mix deps.get
```

* Add node_modules to local git repo (since these will be needed by edeliver to build the release within the Docker container) - might not be needed anymore
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