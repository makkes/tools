# syntax=docker/dockerfile:1

FROM python:3.10-slim-buster

COPY toc-voting.py toc-voting.html.tmpl /app/

WORKDIR /app

ENTRYPOINT ["python", "toc-voting.py"]
