# Arquitectura del Backend

## Objetivo

El backend será desarrollado utilizando Django y Django REST Framework (DRF), siguiendo una arquitectura modular, escalable y mantenible.

Su principal responsabilidad será exponer una API REST segura, consistente y desacoplada del frontend.

Toda la lógica de negocio deberá permanecer en el backend.

---

# Tecnologías

## Framework

- Django

## API

- Django REST Framework (DRF)

## Lenguaje

- Python

## Base de datos

- PostgreSQL

---

# Principios de desarrollo

Todo el código deberá seguir los siguientes principios:

- Clean Architecture (adaptada a Django)
- SOLID
- DRY
- KISS
- Separation of Concerns

El objetivo es que cada componente tenga una única responsabilidad.

---

# Arquitectura

La aplicación estará organizada por módulos (apps de Django).

Cada módulo representará un dominio del negocio y contendrá todos los elementos necesarios para funcionar de forma independiente.

Ejemplo:

apps/

authentication/

users/

notifications/

documents/

reports/

dashboard/

Cada módulo deberá ser autocontenido.

---

# Organización del proyecto

backend/

config/

apps/

common/

core/

media/

static/

requirements/

manage.py

---

# Estructura de una App

Cada aplicación deberá seguir una estructura similar a:

users/

models.py

views.py

serializers.py

services.py

repositories.py

permissions.py

validators.py

urls.py

tests/

Si una aplicación crece demasiado, podrá dividirse en carpetas internas.

---

# Modelos

Los modelos únicamente representarán la estructura de los datos.

No deberán contener lógica de negocio compleja.

---

# Servicios

Toda la lógica de negocio deberá implementarse dentro de servicios.

Ejemplos:

- Crear usuario
- Cambiar contraseña
- Generar reporte
- Enviar notificaciones

Los servicios podrán utilizar modelos, repositorios y otros servicios.

---

# Repositorios

Toda consulta compleja deberá centralizarse en repositorios.

No se deberán escribir consultas complejas dentro de las vistas.

---

# API

Todas las funcionalidades deberán exponerse mediante una API REST.

Las respuestas deberán mantener un formato consistente.

Ejemplo:

{
    "success": true,
    "message": "Usuario creado correctamente.",
    "data": {}
}

En caso de error:

{
    "success": false,
    "message": "El correo ya existe.",
    "errors": {}
}

---

# Serializers

Los serializers serán responsables de:

- Validar datos
- Transformar modelos
- Formatear respuestas

No deberán contener lógica del negocio.

---

# Validaciones

Todas las entradas deberán validarse antes de ejecutar cualquier operación.

Las reglas de negocio no deberán depender únicamente de validaciones del frontend.

---

# Autenticación

Toda autenticación deberá centralizarse.

Los permisos deberán implementarse utilizando el sistema de permisos de Django REST Framework.

Las vistas deberán validar siempre la autenticación antes de ejecutar operaciones protegidas.

---

# Autorización

Cada endpoint deberá definir explícitamente quién puede acceder.

Nunca deberán asumirse permisos implícitos.

---

# Manejo de errores

Todas las excepciones deberán ser controladas.

Nunca deberán enviarse errores internos directamente al cliente.

Los errores deberán registrarse mediante el sistema de logs.

---

# Base de datos

Toda modificación que afecte múltiples registros deberá ejecutarse dentro de transacciones.

Las migraciones deberán mantenerse organizadas.

Nunca deberán modificarse migraciones ya aplicadas en producción.

---

# Archivos

Los archivos deberán almacenarse mediante el sistema de almacenamiento configurado por Django.

No deberán guardarse rutas manualmente.

---

# Configuración

Toda configuración deberá obtenerse mediante variables de entorno.

No deberán existir credenciales dentro del código fuente.

---

# Registro de eventos

Las operaciones importantes deberán registrarse cuando sea necesario.

Ejemplos:

- Inicio de sesión
- Cambio de contraseña
- Eliminación de información
- Acciones administrativas

---

# Rendimiento

Se deberá minimizar el número de consultas utilizando:

- select_related()
- prefetch_related()

Se evitarán consultas repetidas (N+1).

Las consultas costosas deberán optimizarse.

---

# Seguridad

Toda entrada deberá validarse.

Las contraseñas nunca deberán almacenarse en texto plano.

Las respuestas no deberán exponer información sensible.

Se deberán aplicar permisos a todos los endpoints protegidos.

---

# Convenciones

Clases:

UserService

UserRepository

UserSerializer

Variables:

user_email

Constantes:

MAX_FILE_SIZE

Los nombres deberán utilizar inglés.

---

# Pruebas

Cada módulo deberá incluir pruebas unitarias y, cuando corresponda, pruebas de integración.

Las nuevas funcionalidades deberán incorporar pruebas antes de considerarse completas.

---

# Restricciones

No colocar lógica de negocio dentro de las vistas.

No realizar consultas complejas directamente en las vistas.

No duplicar lógica entre módulos.

No acceder directamente a configuraciones sensibles.

No exponer información interna mediante la API.

No modificar migraciones existentes.

---

# Objetivo final

Construir un backend modular, seguro y mantenible que permita incorporar nuevas funcionalidades con el mínimo impacto sobre el código existente y que pueda ser comprendido fácilmente por cualquier desarrollador o agente de IA.