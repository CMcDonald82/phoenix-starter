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

* Get mix deps
```
docker-compose run phoenix mix deps.get
```


To build a release:
* Set the environment variable PHOENIX_STARTER_PROD_HOST to be the domain name you have set up for the server

* Run the container that the build will be performed in
```
docker-compose -f docker-compose.yml -f docker-compose.build.yml up
```

* Build the release
```
mix edeliver build release --verbose
```