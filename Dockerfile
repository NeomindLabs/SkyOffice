FROM node:18-bullseye AS build

WORKDIR /app

RUN corepack enable

COPY package.json yarn.lock ./
COPY server ./server
COPY types ./types
COPY client ./client

ARG VITE_SERVER_URL
ENV VITE_SERVER_URL=$VITE_SERVER_URL

RUN yarn install --frozen-lockfile
RUN yarn --cwd types install --frozen-lockfile
RUN yarn --cwd client install --frozen-lockfile

RUN yarn --cwd client build
RUN npx tsc -p server/tsconfig.server.json
RUN npx tsc --target es6 --module commonjs --esModuleInterop --outDir server/types types/*.ts
RUN mkdir -p server/public && cp -r client/dist/* server/public/

FROM node:18-bullseye-slim AS runtime

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=2567
ENV SERVE_CLIENT=true

COPY --from=build /app/node_modules /app/node_modules
COPY --from=build /app/server/lib /app/server/lib
COPY --from=build /app/server/public /app/server/lib/public
COPY --from=build /app/server/types /app/server/types

EXPOSE 2567

CMD ["node", "server/lib/server/index.js"]
