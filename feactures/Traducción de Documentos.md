## Objetivo

Permitir procesar documentos y generar una versión traducida manteniendo la estructura del documento original.

---

## Requisitos funcionales

### Inicio de traducción

El usuario podrá solicitar la traducción de un documento.

El sistema iniciará el proceso correspondiente.

---

### Procesamiento

El documento deberá dividirse en páginas antes de iniciar la traducción.

Cada página será procesada de forma independiente.

---

### Almacenamiento

Una vez traducida una página, el sistema deberá almacenarla permanentemente en la base de datos.

Cada traducción deberá quedar asociada a:

- Documento.
- Número de página.
- Idioma original.
- Idioma traducido.

---

### Finalización

Cuando todas las páginas hayan sido traducidas:

- El documento deberá marcarse como **Traducido**.
- La traducción quedará disponible para futuras consultas.

---

### Reutilización

Si un documento ya cuenta con una traducción almacenada para el idioma solicitado, el sistema no deberá volver a traducirlo.

En su lugar deberá recuperar la información desde la base de datos.

---

## Reglas de negocio

- Cada documento podrá tener varias traducciones, una por idioma.
- Cada traducción estará compuesta por múltiples páginas.
- Cada página deberá almacenarse de forma independiente.
- Una página traducida nunca deberá volver a procesarse mientras siga siendo válida.
- La lectura siempre utilizará las traducciones almacenadas.

## Flujo
Subir documento

↓

Extraer páginas

↓

Traducir página 1

↓

Guardar página 1

↓

Traducir página 2

↓

Guardar página 2

↓

...

↓

Documento traducido

↓

Lectura

↓

Consultar traducciones almacenadas