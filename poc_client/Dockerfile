# syntax=docker/dockerfile:experimental

FROM python:3.8-slim

RUN mkdir /app

WORKDIR /app

RUN pip3 install poetry

RUN apt-get update && apt-get -y install git openssh-client

ADD . /app

RUN poetry export --without-hashes -f requirements.txt > requirements.txt

RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

RUN --mount=type=ssh pip3 install -r requirements.txt

EXPOSE 5000

ENTRYPOINT ["gunicorn", "--config", "/app/gunicorn_config.py", "application:application"]
