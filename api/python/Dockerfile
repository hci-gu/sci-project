FROM python:3.8.13-buster

WORKDIR /app
COPY ./app /app

RUN pip3 --no-cache-dir install -r requirements.txt

EXPOSE 8080

ENTRYPOINT ["python"]
CMD ["main.py"]