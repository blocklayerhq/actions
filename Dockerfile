FROM blocklayer/bl-cli:beta

RUN apk add -U --no-cache bash curl jq

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
