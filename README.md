# phoenix-starter
A starter Elixir/Phoenix project that can be used as a base to build off of

NOTE: This project can be run inside a Docker container for development (in which case it includes a Postgres database container), for production builds (the container has the same OS (Ubuntu 16.04) as the target server to deploy to so the build can use distillery/edeliver to build a release and deploy it to the server), and for tests.


NOTE: To run a bash shell into the container:
```
docker run -it phoenixstarter_phoenix /bin/bash
```

NOTE: To run inside a Docker container, run all commands as the following:

```
docker-compose [-f docker-compose.<dev|build|test>.yml ...] <service> 
```


* Clone the repo into a new project directory: (note: may be able to make the APP var in edeliver conf automatically use the name of root dir (here phoenix_starter))
```
git clone https://github.com/CMcDonald82/phoenix-starter.git phoenix_starter
```

* Add a public key to the project's top-level directory (this key will be used to SSH into the Docker container for building releases)
```
cp <path-to-ssh-pubkey-on-local-machine> .
```

* Build the Docker container
```
docker-compose build
```

* Get mix deps
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
**[Install Erlang/Elixir](https://elixir-lang.org/install.html#unix-and-unix-like)
**[Install Node.js](https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions)
**[Install Yarn](https://yarnpkg.com/lang/en/docs/install/#linux-tab)
**[Install Phoenix (latest)](https://hexdocs.pm/phoenix/installation.html)
**[Setup SSHd](https://docs.docker.com/engine/examples/running_ssh_service/)
