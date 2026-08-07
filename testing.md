# Estrategia de Testing

## Objetivo

Garantizar que toda funcionalidad implementada funcione correctamente y no introduzca regresiones en el sistema.

---

# Tipos de pruebas

## Pruebas Unitarias

Verifican el funcionamiento individual de cada componente.

Se aplicarán a:

- Servicios
- Casos de uso
- Validaciones
- Utilidades

---

## Pruebas de Integración

Verifican la interacción entre componentes.

Ejemplos:

- API + Base de datos
- Servicios + Repositorios
- Autenticación

---

## Pruebas de Interfaz

Verifican el comportamiento de la interfaz de usuario.

Incluyen:

- Navegación
- Formularios
- Validaciones visuales
- Estados de carga
- Mensajes de error

---

## Cobertura

Toda nueva funcionalidad deberá incluir pruebas.

Las funcionalidades críticas deberán tener una cobertura significativamente mayor que el resto del sistema.

---

## Criterios para finalizar una tarea

Una implementación únicamente podrá considerarse terminada cuando:

- El código compile correctamente.
- Todas las pruebas relacionadas hayan sido ejecutadas.
- No existan pruebas fallidas.
- No existan errores conocidos introducidos por el cambio.
- Se hayan corregido los problemas detectados durante las pruebas.

---

## Reporte

Al finalizar una tarea, deberá indicarse:

- Pruebas ejecutadas.
- Resultado de cada prueba.
- Problemas encontrados.
- Problemas corregidos.

---

## Resultados de la Fase 9 (Testing)

### Pruebas ejecutadas

| Ámbito | Pruebas | Resultado |
|---|---|---|
| Backend (Django) | 159 tests unitarios y de integración | OK |
| Backend cobertura (`apps/`) | `coverage run --source=apps` | 99 % global; 100 % de los módulos de aplicación |
| Backend migraciones | `makemigrations --check --dry-run` | Sin cambios pendientes |
| Backend rendimiento | Galería con traducciones prefetch (sin N+1) y lectura cacheada con límite fijo de queries | OK |
| Frontend | 70 tests (57 unitarios + 13 de widgets) | OK |
| Frontend análisis | `flutter analyze` | Sin issues |
| Frontend build | `flutter build web` | OK |
| Smoke de carga | 20 peticiones concurrentes a la galería contra Docker (10 workers) | 0.22 s, 100 % 200 |

### Problemas encontrados y corregidos

- `LoginPage` y `RegisterPage` declaraban `_formKey` pero el contenido nunca se envolvía en un `Form`, por lo que el envío con campos vacíos fallaba con un null check en tiempo de ejecución. Se añadió el `Form` en `AuthScaffold` (parámetro `formKey`).
- La fila "¿No tienes cuenta? / Registrarse" (y su equivalente en registro) desbordaba el ancho máximo de 420 px del formulario. Se reemplazó por un `Wrap` centrado.
- `GalleryPage` y `DocumentReaderPage` invocaban notifiers en `initState` que modificaban el estado de Riverpod de forma síncrona (prohibido en Riverpod 2), lo que provocaba el error "Tried to modify a provider while the widget tree was building". Se difirieron las llamadas con `addPostFrameCallback`.
- El test `test_str_returns_email` esperaba `Test@Example.com`, pero la normalización de Django conserva `Test@example.com`. Se corrigió la expectativa.