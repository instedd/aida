#!/bin/sh
docker-compose build
docker-compose run --rm app mix deps.get
docker-compose run --rm app mix ecto.setup
docker-compose run --rm node yarn install
