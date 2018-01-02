FROM node:boron

COPY webpack.config.js tsconfig.json tslint.json package.json /app/
COPY test /app/test
COPY src /app/src
RUN cd app && \
  npm install --quiet && \
  npm run lint && \
  npm test && \
  npm run build

CMD ["node", "/app/dist/server.js"]

