FROM elixir:1.7.4-alpine

RUN apk update && \
  apk add --no-cache openssl && \
  rm -rf /var/cache/apk/*

ENV PORT 4000 

WORKDIR /app
COPY . ./

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix compile

CMD ["mix", "phx.server"]
