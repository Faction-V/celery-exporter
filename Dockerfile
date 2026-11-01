# Stage 1: Build
FROM python:3.15-slim-trixie AS builder

ENV PYTHONUNBUFFERED=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

WORKDIR /app/
COPY pyproject.toml poetry.lock /app/
RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt install -y locales libcurl4-openssl-dev libssl-dev build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install -U pip poetry && \
    poetry install --without dev --no-root && \
    rm -rf $POETRY_CACHE_DIR

# Stage 2: Runtime environment
FROM python:3.15-slim-trixie

ENV PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

# The runtime stage ships the base image's OS packages as they were on the day
# the base was published. Upgrade them so a rebuild picks up Debian security fixes.
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

# Nothing installs packages at runtime: remove pip from the base interpreter
# and the virtualenv, and ensurepip with the pip wheel it bundles.
RUN /usr/local/bin/python -m pip uninstall -y pip && \
    "${VIRTUAL_ENV}/bin/python" -m pip uninstall -y pip && \
    rm -rf "$(/usr/local/bin/python -c 'import ensurepip, os; print(os.path.dirname(ensurepip.__file__))')"
COPY . /app/

EXPOSE 9808

RUN adduser --disabled-login exporter

USER exporter

ENTRYPOINT ["python", "/app/cli.py"]
