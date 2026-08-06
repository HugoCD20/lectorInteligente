## Objetivo

El agente deberá colaborar en el desarrollo del proyecto respetando la arquitectura, las convenciones y las reglas establecidas en la documentación.

Toda implementación deberá priorizar la mantenibilidad, escalabilidad y claridad del código.
# Política de Desarrollo
Antes de comenzar cualquier tarea deberá revisar:

- architecture/
- database/
- frontend/
- backend/
- features/
- views/
- testing.md

No deberá realizar implementaciones basadas en suposiciones si la documentación ya define el comportamiento esperado.
## Flujo de trabajo
Leer documentación

↓

Analizar problema

↓

Proponer solución

↓

Esperar aprobación (si aplica)

↓

Implementar

↓

Ejecutar pruebas

↓

Corregir errores

↓

Entregar cambios
## Calidad del código
Todo código deberá ser:

- legible
- modular
- reutilizable
- desacoplado
- documentado cuando sea necesario

No deberá duplicarse lógica.

No deberán existir métodos excesivamente largos.

Las responsabilidades deberán mantenerse separadas.

## Validación obligatoria

Ninguna tarea se considerará finalizada hasta que todas las pruebas correspondientes hayan sido ejecutadas y aprobadas.

Antes de dar una implementación por terminada, el agente deberá:

1. Ejecutar las pruebas unitarias relacionadas con los cambios realizados.
2. Ejecutar las pruebas de integración cuando la funcionalidad afecte la comunicación entre componentes.
3. Corregir cualquier error detectado antes de continuar.
4. Repetir las pruebas hasta obtener un resultado exitoso.
5. Informar qué pruebas fueron ejecutadas y su resultado.

No deberá indicar que una tarea está completa si existen pruebas fallidas o si las pruebas requeridas no fueron ejecutadas.

---

## Modificaciones

Toda modificación deberá mantener la compatibilidad con el resto del sistema.

Si una implementación rompe funcionalidades existentes, deberá corregirse antes de considerar la tarea como finalizada.

---

## Calidad

El código generado deberá mantener el mismo nivel de calidad del proyecto.

No se aceptarán soluciones temporales ("quick fixes") como implementación final.

## Prohibiciones

El agente no deberá afirmar que una funcionalidad funciona correctamente sin evidencia obtenida mediante pruebas.

No deberá asumir que una implementación es correcta únicamente porque el código compila.

Si no puede ejecutar las pruebas por limitaciones del entorno, deberá indicarlo explícitamente y especificar qué pruebas quedan pendientes. En ese caso, la tarea no deberá marcarse como completamente validada.

Nunca:

- modificar migraciones existentes
- eliminar código sin justificarlo
- cambiar nombres públicos sin autorización
- romper compatibilidad
- ignorar errores de compilación
- dejar código comentado
- dejar TODO sin autorización
## manejo de errores
Todos los errores deberán manejarse correctamente.

Nunca deberán ocultarse excepciones.

Nunca deberán capturarse errores con bloques vacíos.

Los mensajes mostrados al usuario deberán ser claros.
## Comunicación
Al finalizar una tarea deberá indicar:

- archivos modificados
- motivo de cada cambio
- pruebas ejecutadas
- posibles riesgos
- siguientes pasos recomendados
## uso de dependencias
No instalar nuevas dependencias sin autorización.

Siempre reutilizar librerías existentes cuando sea posible.

Justificar cualquier nueva dependencia.
## seguridad
Nunca:

- exponer credenciales

- escribir secretos en el código

- desactivar autenticación para facilitar pruebas

- eliminar validaciones
## Rendimiento
Evitar:

consultas innecesarias

widgets pesados

consultas N+1

ciclos redundantes

operaciones costosas dentro de bucles
## Refactorización
No realizar refactorizaciones masivas cuando la tarea no las requiera.

Las modificaciones deberán limitarse al alcance solicitado.

Si se detecta una mejora importante, deberá proponerse antes de implementarla.

## Conservación de arquitectura
Toda implementación deberá respetar la arquitectura existente.

No deberán introducirse nuevos patrones sin autorización.

No deberán mezclarse estilos arquitectónicos.
## Sin falta de información
Si la documentación no define un comportamiento:

No asumir.

Preguntar.

Si existen varias alternativas válidas, explicar cada una y esperar una decisión antes de implementar.