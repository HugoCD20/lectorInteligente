## Objetivo

Permitir a los usuarios cargar, almacenar, visualizar y administrar sus documentos dentro del sistema.

---

## Requisitos funcionales

### Carga de documentos

El sistema deberá permitir cargar un nuevo documento desde la página principal.

El documento deberá ser validado antes de almacenarse.

Los formatos permitidos serán aquellos definidos por el sistema.

El sistema deberá verificar:

- Formato válido.
- Tamaño máximo permitido.
- Integridad del archivo.

---

### Almacenamiento

Una vez aceptado el documento:

- Se almacenará de forma segura.
- Se registrará su propietario.
- Se almacenará la fecha de carga.
- Se generará un identificador único.

---

### Historial reciente

El sistema deberá registrar los documentos abiertos recientemente por cada usuario.

La lista deberá ordenarse del más reciente al más antiguo.

El número de documentos devueltos dependerá del límite solicitado por el frontend.

---

### Galería

El sistema deberá permitir consultar todos los documentos pertenecientes al usuario.

La consulta deberá:

- soportar paginación.
- permitir búsqueda.
- ordenar resultados.
- devolver únicamente documentos del usuario autenticado.

---

### Eliminación

El usuario podrá eliminar documentos de su galería.

La eliminación deberá seguir la política definida por el sistema (eliminación lógica o física).

---

### Reglas de negocio

- Un documento únicamente podrá ser consultado por su propietario.
- Un documento eliminado no deberá mostrarse en la galería.
- Los documentos recientes deberán actualizarse automáticamente cada vez que un documento sea abierto.