# ---------- Etapa 1: build de dependencias ----------
FROM python:3.12-slim AS builder

WORKDIR /app

# Evita archivos .pyc y fuerza salida sin buffer
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Instala dependencias en un prefijo aislado para copiarlas a la imagen final
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Etapa 2: imagen final minimalista ----------
FROM python:3.12-slim AS runtime

# --- Buenas prácticas / mínimo privilegio ---
# Usuario sin privilegios con UID/GID fijos; nunca se ejecuta como root.
RUN groupadd --gid 1001 appgroup \
    && useradd --uid 1001 --gid 1001 --no-create-home --shell /usr/sbin/nologin appuser

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

# Copia solo las dependencias ya instaladas desde la etapa builder
COPY --from=builder /install /usr/local

# Copia el código de la aplicación y cede la propiedad al usuario sin privilegios
COPY --chown=appuser:appgroup . .

# A partir de aquí el contenedor corre como usuario no-root
USER appuser

# Expone únicamente el puerto necesario de la aplicación
EXPOSE 5000

# Healthcheck básico contra la página principal
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request,os; urllib.request.urlopen('http://localhost:'+os.getenv('PORT','5000')+'/')" || exit 1

# Servidor de producción con gunicorn (no el servidor de desarrollo de Flask)
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT:-5000} --workers 2 --timeout 60 app:app"]
