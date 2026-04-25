FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN apt-get update \
    && apt-get install -y --no-install-recommends netcat-openbsd \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir -r requirements.txt

COPY wait-for-db.sh /app/wait-for-db.sh
RUN chmod +x /app/wait-for-db.sh

COPY . /app/api
WORKDIR /app

CMD ["/app/wait-for-db.sh", "db", "5432", "uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
