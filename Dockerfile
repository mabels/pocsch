FROM node:boron

COPY tsconfig.json tslint.json package.json /app/
COPY test /app/test
COPY lib /app/lib
RUN cd app && \
  ls -l && \
  npm install && \
  npm run lint && \
  npm test && \
  npm run build

CMD ["node", "/app/dist/server.js"]

