ARG NODE_VERSION

FROM node:${NODE_VERSION}-alpine

RUN npm install -g browser-sync

USER node

ENTRYPOINT ["browser-sync", "start"]
