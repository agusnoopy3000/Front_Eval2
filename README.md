# Front_Eval2 — Frontend Flask

Frontend del proyecto **Innovatech Chile (EP2 — ISY1101 DuocUC)**. Aplicación web en Flask + Jinja + Bootstrap que consume el API REST del backend. Contenedorizada con Docker y desplegada automáticamente en AWS EC2 vía GitHub Actions.

- **Frontend (este repo):** https://github.com/agusnoopy3000/Front_Eval2
- **Backend:** https://github.com/agusnoopy3000/Back_EVAL2
- **Data (SQL):** https://github.com/agusnoopy3000/Data_Eval2
- **Imagen Docker Hub:** https://hub.docker.com/r/agusnoopy/front-eval2
- **App en vivo:** http://184.73.24.77

---

## 📦 Stack técnico

| Capa | Tecnología | Versión |
|---|---|---|
| Runtime | Python | 3.11 (slim) |
| Framework web | Flask + Jinja2 | 2.3 / 3.1 |
| WSGI productivo | gunicorn | 26.0 |
| UI | Bootstrap + Font Awesome | (CDN) |
| HTTP client | requests | 2.31 |
| Contenedorización | Docker + Compose v2 | 25.0 / v2.29 |
| CI/CD | GitHub Actions (self-hosted runner en EC2) | — |
| Registry | Docker Hub público | — |
| Host | AWS EC2 Amazon Linux 2023 (t2.micro) | — |

---

## 🗂️ Estructura del repositorio

```
Front_Eval2/
├── .github/workflows/deploy.yml   # Pipeline CI/CD
├── templates/                     # Vistas Jinja2
│   ├── base.html
│   ├── index.html                 # Lista de usuarios
│   ├── crear_usuario.html
│   ├── editar_usuario.html
│   ├── 404.html
│   └── 500.html
├── .dockerignore
├── .env.example
├── .gitignore
├── Dockerfile                     # Multi-stage: builder + runtime no-root
├── app.py                         # Entrypoint Flask
├── docker-compose.yml
├── requirements.txt
└── README.md
```

---

## 🐳 Contenedorización (IE1)

### Dockerfile multi-stage

```dockerfile
# Stage 1: builder — venv aislado con dependencias + gunicorn
FROM python:3.11-slim AS builder
WORKDIR /app
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Stage 2: runtime — imagen final mínima
FROM python:3.11-slim AS runtime
RUN groupadd -r app && useradd -r -g app -m -d /home/app app
COPY --from=builder /opt/venv /opt/venv
WORKDIR /app
COPY --chown=app:app . .
USER app
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PORT=5000
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
```

**Buenas prácticas aplicadas:**
- ✅ **Multi-stage** → la imagen final no incluye pip cache ni archivos temporales de build.
- ✅ **Python slim** → imagen base ~120MB (vs ~900MB de la full).
- ✅ **Virtual environment aislado** copiado entre stages → control total de dependencias.
- ✅ **Usuario no-root** (`app`) con `$HOME` propio → gunicorn no falla escribiendo control socket.
- ✅ **`pip install --no-cache-dir`** → reduce tamaño final.
- ✅ **gunicorn** en vez del dev server de Flask → producción real, 2 workers concurrentes.

### docker-compose.yml

```yaml
services:
  frontend:
    image: ${DOCKERHUB_USERNAME}/front-eval2:latest
    container_name: eval2-front
    restart: unless-stopped
    environment:
      PORT: 5000
      BACKEND_URL: ${BACKEND_URL}        # URL del backend (IP privada en AWS)
      SECRET_KEY: ${SECRET_KEY}
      DEBUG: "False"
    ports:
      - "80:5000"                        # Expone HTTP estándar 80 al exterior
```

**Decisiones clave:**
- El front es **stateless** → no necesita volúmenes (toda la persistencia está en el backend).
- Mapeo `80:5000` → el usuario accede por puerto 80 (HTTP estándar, no requiere `:5000`).
- `BACKEND_URL` se inyecta por variable de entorno → la misma imagen sirve para local (`localhost:3000`) y producción (`172.31.31.128:3000` IP privada AWS).
- `restart: unless-stopped` → si el contenedor crashea, Docker lo levanta solo.

---

## 🚀 CI/CD GitHub Actions (IE3 + IE7)

### Flujo del pipeline (`.github/workflows/deploy.yml`)

```
push a rama "deploy"
       ↓
[1] Checkout código
       ↓
[2] Login Docker Hub
       ↓
[3] Build imagen multi-stage
       ↓
[4] Push a Docker Hub (agusnoopy/front-eval2:latest + :SHA-commit)
       ↓
[5] Deploy local (runner está en EC2-front):
    - cp docker-compose.yml ~/app/
    - docker compose pull
    - docker compose up -d
    - docker image prune
       ↓
✅ App actualizada en http://184.73.24.77
```

### Trigger: rama `deploy`

```yaml
on:
  push:
    branches: [deploy]
  workflow_dispatch:
```

Solo los pushes a `deploy` disparan despliegue. Trabajar en `main` o feature branches es seguro.

### Self-hosted runner

Instalado en la propia **EC2-front** como systemd service. Cada repo tiene su runner dedicado en su EC2 destino → reparte carga y elimina dependencias entre máquinas.

### GitHub Secrets

| Secret | Uso |
|---|---|
| `DOCKERHUB_USERNAME` | Login Docker Hub |
| `DOCKERHUB_TOKEN` | Personal Access Token (Read & Write) |
| `EC2_HOST` | IP pública (referencia) |
| `EC2_USER` | `ec2-user` |
| `EC2_SSH_KEY` | Contenido del .pem (referencia) |

Configurados vía `gh secret set` o desde Settings → Secrets and variables → Actions.

---

## 🌐 Arquitectura en AWS (IE6)

```
                       Internet
                          │
                          │ HTTP :80
                          ▼
              ┌───────────────────────┐
              │  EC2 eval2-front      │
              │  IP pública: 184.73.24.77
              │  SG-Frontend (22, 80) │
              │                       │
              │  Container eval2-front│
              │  • Flask + gunicorn   │
              │  • BACKEND_URL=       │
              │    http://172.31.31.128:3000  ← red privada
              └────────────┬───────────┘
                           │
                           ▼ (solo SG-Frontend puede llegar al :3000)
              ┌───────────────────────┐
              │  EC2 eval2-back       │
              │  SG-Backend (22, 3000 desde SG-Frontend)
              │  eval2-back + eval2-mysql
              └───────────────────────┘
```

**Comunicación segura Front → Back:**
- Frontend usa la **IP privada AWS** del backend (172.31.31.x), no la pública.
- Tráfico nunca sale a Internet — pasa por la red privada VPC.
- Security Group del backend solo acepta puerto 3000 desde el SG del frontend.

---

## 🛠️ Uso local

```bash
git clone https://github.com/agusnoopy3000/Front_Eval2.git
cd Front_Eval2

cp .env.example .env
# Edita .env:
#   DOCKERHUB_USERNAME=tu-usuario
#   BACKEND_URL=http://host.docker.internal:3000  (apunta al back local)
#   SECRET_KEY=loquesea

docker build -t agusnoopy/front-eval2:latest .
docker compose up -d
open http://localhost
```

---

## 🧪 Probar el ciclo CI/CD

```bash
git checkout deploy
# Editar templates/index.html (ej: cambiar el <h1>)
git commit -am "demo: cambio visible"
git push origin deploy
# Watch: https://github.com/agusnoopy3000/Front_Eval2/actions
# El cambio aparece en http://184.73.24.77 en ~20 segundos
```

---

## 📚 Asignatura

ISY1101 Introducción a Herramientas DevOps — DuocUC. EP2 Innovatech Chile (etapa 2).
