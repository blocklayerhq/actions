FROM blocklayer/bl-dev:alpha-3

RUN apk add -U --no-cache bash curl jq

COPY ingest.sh /ingest.sh
ENTRYPOINT ["/ingest.sh"]
