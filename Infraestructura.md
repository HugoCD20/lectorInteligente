# Infraestructura

El sistema estará compuesto por múltiples servicios ejecutándose de forma independiente mediante Docker.

Inicialmente la infraestructura estará conformada por:

- Backend Django
- PostgreSQL
- LibreTranslate

Todos los servicios deberán comunicarse mediante la red interna de Docker.

No deberán utilizarse direcciones IP fijas.

La comunicación deberá realizarse utilizando el nombre del servicio definido en Docker Compose.