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