FROM node:boron

WORKDIR /app
COPY webpack.config.js tsconfig.json tslint.json package.json /app/
COPY test /app/test
COPY src /app/src
RUN pwd && \
  npm install --quiet && \
  npm run lint && \
  npm test && \
  npm run build

CMD ["node", "dist/server.js"]

