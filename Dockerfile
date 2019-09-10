FROM blocklayer/bl-dev:alpha-2

RUN apk add -U --no-cache bash curl jq

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
