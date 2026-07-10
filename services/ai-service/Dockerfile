FROM python:3.11-slim

WORKDIR /app

COPY pyproject.toml .
RUN pip install --no-cache-dir -e ".[dev]"

COPY . .

EXPOSE 8084
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8084", "--workers", "4"]
