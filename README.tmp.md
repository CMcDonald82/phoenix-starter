
This project includes:
* Erlang/Elixir (latest)
* Phoenix (latest - 1.3)
* Node.js (v 8.x)
* Webpack
* PostgreSQL 10

This project can be used for:
* Local Development: Run locally inside a Docker container, which includes a Postgres database container
* Production Builds: The Docker container has the same OS (Ubuntu 16.04) as the target server to deploy to so the build can use Distillery/Edeliver to build a release and deploy it to the server
* Tests: Tests (for the Phoenix app) will be run inside a Docker container, providing an even more isolated test environment

This project also includes an /assets directory setup with Webpack (instead of Brunch, which is Phoenix's default) and some basic npm packages. This allows you to build the frontend however you want. Phoenix's html features are also intact so you can use this project to build a standard app with Phoenix taking care of both the backend and frontend. Or you can do a bit of both (for example, standard, Phoenix-rendered pages with React components included in some of them). It's really up to you.

## Setup

1. Add a public key to the project's top-level directory (this key will be used to SSH into the Docker container for building releases)
```
cp <path-to-ssh-pubkey-on-local-machine> ./ssh_key.pub
```

NOTE: The containers in steps 2.a and 2.b MUST be built before going further since some of the following steps depend on them

2. a.) Build the base Docker container (must be named phoenix-base since the docker-compose files depend on it). This container will be used for local development/debugging and running tests (locally and via Travis)
```
docker build --target base -t phoenix-base:latest .
```

2. b.) Build the build Docker container (must be named phoenix-build since the docker-compose files depend on it). This container will be used to build releases in
```
docker build -t phoenix-build:latest .
```

3. Set environment variables locally: (probably don't need to set these until we build/deploy the release since they're not used in dev)
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
You could optionally create a file called .env in the top-level directory of this project which just includes the exported environment variables as listed above (.env is included in .gitignore by default so your environment variable settings will not be committed to your repo for security). You could then source the .env file from the top-level directory of the project to set all the variables at once for the shell you're currently in:
```
source .env
```

4. Get mix deps 
```
docker-compose run phoenix mix deps.get
```

5. Install frontend dependencies (via Yarn) 
```
docker-compose run -w /app/assets phoenix yarn install
```

6. Run the mix setup task to rename the app, create a new README, and initialize a fresh git repo for the new project
NOTE: Before running this task, you can optionally edit the config in config/setup.exs. You can specify the new name and otp_name of the project in either of 2 ways: pass the names in via the command line (as in the command below), or set the values of 'name' and 'otp_name' in the setup config file (config/setup.exs). You can also set git_reinit: true in the config/setup.exs file to have the setup task initialize a fresh new git repo for your new project.
```
docker-compose run phoenix mix setup PhoenixStarter <NewName> phoenix_starter <new_otp_name>

EXAMPLE: If we want to rename our new project to My App this command would be:
docker-compose run phoenix mix setup PhoenixStarter MyApp phoenix_starter my_app
Alternatively, we could set name: "MyApp" and otp_name: "my_app" in config/setup.exs and run the setup task without args:
docker-compose run phoenix mix setup
```

7. Create and migrate the database 
```
docker-compose run phoenix mix ecto.create
docker-compose run phoenix mix ecto.migrate
```


## Local Development 
After going through the steps in the Setup section, you should now be ready to run the app for local development:
```
docker-compose up
```
Visit http://localhost:4000 and you should see your new app running (it's the standard 'Welcome To Phoenix!' page)

If you make changes to files in assets/css or assets/js, you should see the changes reflected in the browser immediately when you save the file since Webpack's hot reloading is enabled.

## Deployment

1. Set environment variables on remote host:
  NOTE: These variables can be set either manually or using a provisioning tool such as Ansible. Check out (and feel free to use, if you'd like) [this Ansible playbook](https://github.com/CMcDonald82/ansible-playbook-ubuntu-phoenix) for an example of how to set these variables (and how to setup the remote host for deploying a Phoenix app in general)
  - REPLACE_OS_VARS: This is necessary for environment variables that are written as "${VARIABLE}" to be expanded.
  - DB_NAME: The name of the production database. This can be whatever you want, but a database with this name must be created on the remote host (this can be done manually or via a provisioning tool like the Ansible playbook linked above).
  - DB_USERNAME: This is the username of the user that will be connecting to the prod database. This user should be created on the server along with the production database (this can be done manually or via provisioning tool like the Ansible playbook linked above). 
  - DB_PASSWORD: The password for the user that will be connecting to the prod database. 
  - DB_HOSTNAME: The hostname of the server where the database will be. We can set this to localhost if we are running the database on the same host as the app.
  - SECRET_KEY_BASE: This is a token that is used by the Phoenix app. The command to generate a secret key is listed in the 'Other Useful Commands' section.
  - DOMAIN_NAME: The domain name for the remote server (ex. example.com). You will need to have obtained, setup and configured this separately (obtain domain name and set it up to point to the server you will be deploying your app to). See [this tutorial](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-host-name-with-digitalocean) for some instructions on how to do this (although this tutorial is for DigitalOcean, the steps are pretty generic and apply no matter what provider you're using).
  - PORT: The port that the Phoenix app will be running on. You can set this to 4000.
  - PHOENIX_OTP_APP_NAME: Set this to the same value you set it to locally (the snake_case version of the name you want to give your new app).
  - ERLANG_COOKIE: This cookie is necessary for distributed Erlang apps to communicate with each other (see section 13.7 Security in the [Erlang docs](http://erlang.org/doc/reference_manual/distributed.html). Since we are setting this value via a custom vm.args file (vm.args.prod), we do not need to worry about setting it via the rel/config.exs file so you can leave the 'set cookie: "ignore"' line in that file. This will prevent Distillery from displaying a warning that the cookie has not been set (which will be an error in a future version of Distillery). It's fine to do this since the cookie will actually be set on the remote host when the app is deployed and started as long as the ERLANG_COOKIE variable is set on the remote host. This project includes a mix task "erlang_cookie" which will generate a token that can be used as the value of this variable. The erlang_cookie task will output the value to a file in this project called .erlang_cookie - you can then copy this value and set ERLANG_COOKIE on your remote host to this value. The .erlang_cookie file is ignored by git by default and can be deleted or regenerated/overwritten by running the erlang_cookie task again. Outputting the cookie to a file prevents the it from being output to the console or worse, checked into the git repo which could be a security risk. The task can be run as follows (inside a Docker container):
```
docker-compose run phoenix mix erlang_cookie
```

```
Example of all the environment variables that need to be set on server:

export REPLACE_OS_VARS=true
export DB_NAME=phoenix_starter_prod
export DB_USERNAME=postgres
export DB_PASSWORD=my_secret_password
export DB_HOSTNAME=localhost
export SECRET_KEY_BASE=<output of mix phx.gen.secret>
export DOMAIN_NAME=example.com
export PORT=4000
export PHOENIX_OTP_APP_NAME="<new_name>"
export ERLANG_COOKIE=<output of erlang_cookie task>
```

* Make sure you've set the local environment variable PHOENIX_STARTER_PROD_HOST to be the domain name you have set up for the server (this should already have been done in step 4 of the 'Setup' instructions, above)

* Run the container that the build will be performed in (do this in a separate terminal tab)
```
docker-compose -f docker-compose.yml -f docker-compose.build.yml up
```

NOTE: The following steps will be done OUTSIDE the Docker container. You can open up a new tab in the terminal to run these commands (just make sure you're in the root directory of the project).

* Run mix deps.get. This is necessary since we will be running the Edeliver commands outside a Docker container.
```
mix deps.get
```

NOTE: The first time you run the container, ssh into it before building the release. Do this from a different terminal window than the one the build container is running in. 
```
ssh builder@localhost
```
Type yes at the prompt 'Are you sure you want to continue connecting (yes/no)'?

If you get the following warning, you can remove the existing ssh key that's in the known_hosts file so it can be replaced with the new, updated one. This scenario can happen if you build the container, then delete it, then build it again. 
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```
Run the following command to remove the existing ssh key that's in the known_hosts file
```
ssh-keygen -R localhost
```
You should see a message that looks like the following:
```
# Host localhost found: line 16
/Users/chris/.ssh/known_hosts updated.
Original contents retained as /Users/chris/.ssh/known_hosts.old
```
Now, just try to ssh into the build container again and type yes at the prompt 'Are you sure you want to continue connecting (yes/no)'? You should now be in the container. Exit the container so you can continue running commands.
```
builder@57c31b3f3abb:~$ exit
```

* Commit locally
```
git commit -am 'commit message'
```

* Build the release
```
mix edeliver build release --verbose
```

* Deploy the release
```
mix edeliver deploy release to production --verbose
```

* Start the release on remote server
```
mix edeliver start production
```


You should be all set! Visit the domain you set up (i.e. example.com) in any browser and you should see your Phoenix app up and running!

## Other Useful Commands

* Stop the release on remote server
```
mix edeliver stop production
```

* Migrate the database on remote server
```
mix edeliver migrate production
```

* To run commands inside a Docker container, run them as follows:
```
docker-compose [-f docker-compose.<dev|build|test>.yml ...] run <service> <command>
```

* Run a bash shell in the container:
```
docker-compose run phoenix /bin/bash
```

* Generate a secret key for Phoenix app
```
docker-compose run phoenix mix phx.gen.secret
```

## Notes/Links

* Docker
  - [Install Erlang/Elixir](https://elixir-lang.org/install.html#unix-and-unix-like)
  - [Install Node.js](https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions)
  - [Install Yarn](https://yarnpkg.com/lang/en/docs/install/#linux-tab)
  - [Install Phoenix (latest)](https://hexdocs.pm/phoenix/installation.html)
  - [Setup SSHd](https://docs.docker.com/engine/examples/running_ssh_service/)