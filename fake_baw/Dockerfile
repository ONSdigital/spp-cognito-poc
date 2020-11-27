FROM python:3.8-slim

RUN mkdir /app

WORKDIR /app

RUN pip3 install poetry

ADD . /app

RUN poetry export --without-hashes -f requirements.txt > requirements.txt

RUN pip3 install -r requirements.txt

EXPOSE 5000

ENTRYPOINT ["gunicorn", "--config", "/app/gunicorn_config.py", "application:application"]
