FROM elixir:latest

WORKDIR /app
COPY . ./

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix compile

ENV PORT 4000 

CMD ["mix", "phx.server"]
