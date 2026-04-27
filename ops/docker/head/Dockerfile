FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ../requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ../dev/gatekeeper.py /app/
COPY ../dev/inbox_poller.py /app/
COPY ../dev/worker.py /app/
COPY ../sec/config/ ./config/

ENV PYTHONUNBUFFERED=1
ENV PLANE_URL=http://proxy:80
ENV OLLAMA_HOST=http://host.docker.internal:11434

CMD ["python", "inbox_poller.py"]