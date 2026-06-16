# Frontend - Aplicación Web con Flask

## Descripción
Frontend desarrollado en Python con el framework Flask. Proporciona una interfaz web completa para la gestión de usuarios, con comunicación RESTful con el backend API.

## Versiones y Herramientas Requeridas

### Lenguaje y Runtime
- **Python**: Versión 3.8 o superior
- **pip**: Versión 21.0 o superior (gestor de paquetes de Python)

### Dependencias Principales
- **Flask**: ^2.3.3 - Framework web micro para Python
- **Flask-CORS**: ^4.0.0 - Middleware para habilitar CORS
- **requests**: ^2.31.0 - Librería para peticiones HTTP
- **python-dotenv**: ^1.0.0 - Manejo de variables de entorno
- **Jinja2**: ^3.1.2 - Motor de plantillas (incluido con Flask)

## Instalación

```bash
# Crear entorno virtual (recomendado)
python -m venv venv

# Activar entorno virtual
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt
```

## Configuración

1. Copiar el archivo de variables de entorno:
```bash
cp .env.example .env
```

2. Editar el archivo `.env` con tu configuración:
```
PORT=5000
DEBUG=False
BACKEND_URL=http://localhost:3000
SECRET_KEY=clave_secreta_muy_segura_aqui
```

## Ejecución

```bash
# Para desarrollo
python app.py

# O con variables de entorno
FLASK_ENV=development python app.py
```

## Estructura del Proyecto

```
frontend/
├── app.py                 # Aplicación principal Flask
├── requirements.txt       # Dependencias Python
├── .env.example          # Ejemplo de variables de entorno
├── .env                  # Variables de entorno (crear manualmente)
├── templates/            # Plantillas HTML
│   ├── base.html         # Plantilla base
│   ├── index.html        # Página principal
│   ├── crear_usuario.html# Formulario crear usuario
│   ├── editar_usuario.html# Formulario editar usuario
│   ├── 404.html          # Página error 404
│   └── 500.html          # Página error 500
├── static/               # Archivos estáticos (CSS, JS, imágenes)
└── README.md             # Este archivo
```

## Funcionalidades

### Páginas Disponibles
- **Página Principal (`/`)**: Lista todos los usuarios con opciones de CRUD
- **Crear Usuario (`/crear`)**: Formulario para agregar nuevos usuarios
- **Editar Usuario (`/editar/<id>`)**: Formulario para modificar usuarios existentes
- **Eliminar Usuario**: Botón de acción en la lista principal

### Características Técnicas
- **Responsive Design**: Interfaz adaptable a diferentes dispositivos
- **Bootstrap 5**: Framework CSS para estilos modernos
- **Font Awesome**: Iconos profesionales
- **Validación**: Validación en cliente y servidor
- **Mensajes Flash**: Notificaciones al usuario
- **Manejo de Errores**: Páginas personalizadas para errores 404 y 500

## Comunicación con Backend

La aplicación se comunica con el backend API mediante peticiones HTTP REST:

```python
# Ejemplo de petición GET para obtener usuarios
response = requests.get(f'{BACKEND_URL}/api/usuarios')
usuarios = response.json()

# Ejemplo de petición POST para crear usuario
response = requests.post(f'{BACKEND_URL}/api/usuarios', json=datos_usuario)
```

## Puertos Requeridos

### Para funcionamiento en contenedor:
- **Puerto 5000**: Puerto del servidor frontend Flask (HTTP)
- **Puerto 3000**: Puerto de comunicación con backend API (externo)

### Explicación de puertos:
- **5000**: Es el puerto donde escucha el servidor Flask para servir la aplicación web
- **3000**: Es el puerto del backend API al que el frontend se conecta para obtener/enviar datos

## Variables de Entorno

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `PORT` | Puerto del servidor Flask | 5000 |
| `DEBUG` | Modo debug (True/False) | False |
| `BACKEND_URL` | URL del backend API | http://localhost:3000 |
| `SECRET_KEY` | Clave secreta para sesiones | clave_secreta_por_defecto |

## Notas Importantes
- El backend API debe estar corriendo antes de iniciar el frontend
- Asegúrate de que las URLs en las variables de entorno sean correctas
- En producción, establece `DEBUG=False` y usa una `SECRET_KEY` segura
- La aplicación está diseñada para funcionar con el backend API de este proyecto


## Despliegue DevOps (EFT)

CI/CD con GitHub Actions + despliegue en AWS ECS Fargate. Ver [ARQUITECTURA.md](ARQUITECTURA.md) para el detalle de contenerización, pipeline, infraestructura y diagrama.
