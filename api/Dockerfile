FROM nikolaik/python-nodejs:python3.8-nodejs17

ADD ./requirements.txt /python/requirements.txt

RUN pip3 install -r /python/requirements.txt

COPY lib lib
COPY package.json .
COPY yarn.lock .

RUN yarn

EXPOSE 4000

CMD yarn start