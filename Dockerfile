FROM mhart/alpine-node:14

COPY lib lib
COPY package.json .
COPY yarn.lock .

RUN yarn

EXPOSE 4000

CMD yarn start