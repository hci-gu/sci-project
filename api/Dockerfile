FROM node:16.14

COPY lib lib
COPY package.json .
COPY yarn.lock .
COPY tsconfig.json .

RUN yarn
RUN yarn build

EXPOSE 4000

CMD yarn start-prod