## Objetivo

Administrar el almacenamiento y recuperación de las traducciones generadas por el sistema.

---

## Requisitos funcionales

### Consulta

El sistema deberá recuperar las traducciones almacenadas sin volver a ejecutar el proceso de traducción.

---

### Organización

Cada traducción deberá estar organizada por:

- Documento
- Idioma
- Página

---

### Recuperación

Durante la lectura del documento:

- Se recuperará la traducción correspondiente a cada página.
- No se realizarán llamadas al motor de traducción.

---

### Actualización

Si una traducción deja de ser válida (por ejemplo, porque el documento cambió), el sistema deberá invalidarla antes de permitir una nueva traducción.

---

### Eliminación

Cuando un documento sea eliminado, sus traducciones deberán eliminarse conforme a la política definida para el proyecto (eliminación lógica o física).

---

## Reglas de negocio

- No deberán existir traducciones sin documento asociado.
- No podrán existir dos traducciones para la misma página, documento e idioma.
- Las traducciones deberán mantenerse sincronizadas con el documento original.