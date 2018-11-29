FROM elixir:1.5-alpine

ENV PORT 4000 

WORKDIR /app
COPY . ./

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix compile

CMD ["mix", "phx.server"]
