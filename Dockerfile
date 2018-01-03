FROM elixir:1.5.2

RUN mix local.hex --force
RUN mix local.rebar --force

ENV MIX_ENV=prod

ADD mix.exs mix.lock /app/
ADD config /app/config
WORKDIR /app

RUN mix deps.get --only prod
RUN mix deps.compile

ADD . /app
RUN mix compile

ENV PORT=80
EXPOSE 80

CMD elixir --sname server -S mix phx.server
