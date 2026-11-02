# CLAUDE.md

Source of truth for coding agents in this repo. `AGENTS.md` is a symlink to this file: edit `CLAUDE.md` only.

The umbrella org contract applies to every task here: [Faction-V/umbrella `CLAUDE.md`](https://github.com/Faction-V/umbrella/blob/main/CLAUDE.md). This file wins only for this repo's stack, checks and gotchas. Start each task with umbrella `scripts/agent-preflight.sh`; after `gh pr create`, follow umbrella `docs/runbooks/pr-review-loop.md`.

## What this is

Capitol's fork of the upstream Celery Prometheus exporter (`danihodovic/celery-exporter`). It reads qdrant-svc's Celery broker and serves `/metrics` and `/health`. KEDA scales qdrant-svc's ingest workers on its `celery_worker_tasks_active` metric, so it is required, not optional monitoring. `README.md` is upstream's.

- Branch: `master` is the only branch. PRs go into `master`.
- Stack: Python, Poetry (`pyproject.toml`), Black, mypy, pylint, pytest. `charts/celery-exporter/` and `celery-mixin/` come from upstream.

## Before a PR

What `.github/workflows/ci.yml` runs:

```bash
poetry install --no-interaction --no-root
poetry run black . --check
poetry run mypy .
poetry run pylint $(git ls-files -- '*.py' ':!:**/migrations/*.py')
poetry run pytest --broker=memory --ignore .poetry --cov   # CI also runs --broker=redis and --broker=rabbitmq against service containers
```

`helm-test.yml` runs `ct lint` and `ct install` on PRs that touch the chart.

## Ship a change

No Capitol CI builds or deploys this image. `push-image-ghcr.yml`, `helm-release.yml` and `Taskfile.yml` are upstream's; Capitol does not deploy from them. The image is built by hand, pushed to ECR and pinned by digest in the qdrant-svc chart in `gofigure_terraform`. Steps, live check and worked example: umbrella [`repos/celery-exporter.md`](https://github.com/Faction-V/umbrella/blob/main/repos/celery-exporter.md).

## Gotchas

- No workspace uses the ECR tag `latest`; they pin digests.
- Upstream `master` moves on its own. Take upstream releases on purpose, not every commit.
