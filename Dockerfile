FROM --platform=linux/amd64 factoriotools/factorio

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
COPY ./server/map-settings.json /factorio/config/map-settings.json
COPY ./server/map-gen-settings.json /factorio/config/map-gen-settings.json
COPY ./server/server-settings.json /factorio/config/server-settings.json

ENTRYPOINT [ "/docker-entrypoint.sh" ]