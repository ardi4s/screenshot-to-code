# ---- stage 1: build frontend ----
FROM node:22-bookworm-slim AS fe
WORKDIR /app
RUN npm install -g pnpm@10.32.1
COPY frontend/package.json frontend/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY frontend/ ./
RUN pnpm run build

# ---- stage 2: backend + static ----
FROM python:3.12.3-slim-bookworm
ENV POETRY_VERSION=1.8.0
RUN pip install "poetry==$POETRY_VERSION"
WORKDIR /app
COPY backend/poetry.lock backend/pyproject.toml ./
RUN poetry config virtualenvs.create false && poetry install
RUN playwright install --with-deps chromium
COPY backend/ ./
COPY --from=fe /app/dist ./static
EXPOSE 7001
CMD ["sh", "-c", "poetry run uvicorn main:app --host 0.0.0.0 --port ${PORT:-7001}"]
