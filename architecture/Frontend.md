# Arquitectura del Frontend

## Objetivo

El frontend del proyecto será desarrollado utilizando Flutter con el objetivo de crear una aplicación moderna, escalable, mantenible y desacoplada.

Toda la arquitectura deberá facilitar la incorporación de nuevas funcionalidades sin afectar las existentes y promover la reutilización de componentes.

---

# Tecnologías

## Framework

- Flutter

## Lenguaje

- Dart

## Plataforma objetivo

- Android
- iOS
- Web
- Windows 

---

# Principios de desarrollo

Todo el código deberá seguir los siguientes principios:

- Clean Architecture
- SOLID
- DRY
- KISS
- Separation of Concerns

Las reglas de negocio nunca deberán implementarse directamente dentro de las pantallas.

---

# Arquitectura

La aplicación seguirá una arquitectura por capas.

Presentación

↓

Dominio

↓

Datos

La capa de presentación nunca accederá directamente a la base de datos ni a la API.

Toda comunicación deberá realizarse mediante repositorios.

---

# Organización del proyecto

lib/

core/

config/

features/

shared/

main.dart

Cada funcionalidad deberá vivir dentro de la carpeta features.

Ejemplo

features/

authentication/

dashboard/

profile/

settings/

notifications/

Cada feature deberá ser completamente independiente.

---

# Estructura de una Feature

Cada módulo deberá contener como mínimo:

- presentation
- domain
- data

presentation/

Pantallas

Widgets

Controladores

domain/

Casos de uso

Entidades

Repositorios (interfaces)

data/

Modelos

Implementaciones

Datasource remoto

Datasource local

---

# Gestión del estado

Toda la gestión del estado deberá utilizar una única solución durante todo el proyecto.

No se permitirá mezclar diferentes gestores de estado.

El estado deberá permanecer desacoplado de la interfaz gráfica.

---

# Navegación

La navegación deberá estar centralizada.

No deberán utilizarse rutas escritas manualmente dentro de los widgets.

Las rutas deberán declararse en un único archivo de configuración.

---

# Consumo de API

Toda comunicación con el backend deberá realizarse mediante una capa de servicios.

No se permitirá realizar llamadas HTTP directamente desde las pantallas.

Cada servicio deberá encargarse de:

- enviar solicitudes
- procesar respuestas
- transformar modelos
- manejar errores

---

# Manejo de errores

Todos los errores deberán mostrar mensajes amigables para el usuario.

Los errores técnicos deberán registrarse mediante el sistema de logs.

Nunca deberán mostrarse excepciones directamente en la interfaz.

---

# Diseño

Toda la aplicación utilizará un sistema de diseño consistente.

Los colores, tipografías, tamaños y espaciados deberán centralizarse.

No se permitirán valores mágicos dentro de los widgets.

---

# Componentes reutilizables

Todo componente utilizado en más de una pantalla deberá convertirse en un widget reutilizable.

Ejemplos:

- Botones
- Inputs
- Cards
- Diálogos
- Barras de búsqueda
- Tablas
- Selectores

---

# Convenciones

Los nombres deberán utilizar inglés.

Clases:

UserProfilePage

Widgets:

PrimaryButton

Variables:

userName

Constantes:

kPrimaryColor

Archivos:

user_profile_page.dart

---

# Internacionalización

Toda cadena visible para el usuario deberá ser traducible.

No se permitirá escribir textos directamente dentro de los widgets.

---

# Accesibilidad

Toda pantalla deberá considerar:

- tamaños dinámicos de texto
- contraste adecuado
- etiquetas semánticas
- navegación mediante teclado cuando aplique

---

# Rendimiento

Las listas deberán implementar carga bajo demanda cuando el volumen de información lo requiera.

Las imágenes deberán optimizarse.

Los widgets deberán reconstruirse únicamente cuando sea necesario.

---

# Restricciones

No colocar lógica de negocio dentro de los widgets.

No consumir APIs desde la interfaz.

No duplicar componentes.

No duplicar estilos.

No acceder directamente a la base de datos.

No utilizar variables globales para compartir estado.

---

# Objetivo final

Mantener un frontend desacoplado, escalable y fácil de mantener, permitiendo que cualquier desarrollador o agente de IA pueda comprender la estructura del proyecto e implementar nuevas funcionalidades siguiendo un patrón consistente.