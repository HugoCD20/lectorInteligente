# Arquitectura de la Base de Datos

## Objetivo

La base de datos será desarrollada utilizando PostgreSQL.

Su diseño deberá garantizar integridad, consistencia, escalabilidad y un alto rendimiento para soportar el crecimiento del sistema.

Toda la información persistente del sistema deberá almacenarse mediante un modelo relacional normalizado.

---

# Motor de Base de Datos

- PostgreSQL

---

# Principios de diseño

La base de datos deberá seguir los siguientes principios:

- Integridad referencial
- Normalización (hasta donde sea conveniente)
- Evitar duplicidad de información
- Consistencia de datos
- Escalabilidad
- Alto rendimiento

---

# Organización

Cada entidad del negocio deberá tener una única tabla responsable.

Las relaciones entre entidades deberán implementarse mediante claves foráneas.

No se permitirá almacenar información duplicada cuando pueda obtenerse mediante relaciones.

---

# Convenciones de nombres

## Tablas

Todas las tablas deberán utilizar nombres en inglés y en plural.

Ejemplos

users

roles

documents

notifications

audit_logs

---

## Columnas

Las columnas utilizarán snake_case.

Ejemplos

first_name

created_at

updated_at

deleted_at

---

## Llaves primarias

Todas las tablas deberán contar con una llave primaria.

Ejemplo

id

---

## Llaves foráneas

Las llaves foráneas deberán seguir el formato:

user_id

role_id

document_id

---

# Campos comunes

Siempre que aplique, las tablas deberán incluir:

id

created_at

updated_at

Opcionalmente:

deleted_at

created_by

updated_by

---

# Relaciones

Las relaciones deberán implementarse utilizando claves foráneas.

No se almacenarán listas de identificadores dentro de una columna.

Ejemplo incorrecto

roles = "1,2,3"

Ejemplo correcto

Tabla intermedia:

user_roles

---

# Integridad

Toda llave foránea deberá tener restricciones de integridad.

Las eliminaciones en cascada únicamente deberán utilizarse cuando tengan sentido desde el punto de vista del negocio.

---

# Índices

Se deberán crear índices para:

- Llaves foráneas
- Campos utilizados frecuentemente en filtros
- Campos utilizados para búsquedas
- Campos utilizados para ordenar información

No deberán crearse índices innecesarios.

---

# Auditoría

Las operaciones críticas deberán poder auditarse cuando el negocio lo requiera.

Ejemplos:

- Inicio de sesión
- Eliminación de registros
- Cambios de permisos
- Modificación de información sensible

---

# Soft Delete

Cuando una entidad no deba eliminarse físicamente, se utilizará eliminación lógica.

Ejemplo:

deleted_at

Los registros eliminados lógicamente no deberán aparecer en consultas normales.

---

# Archivos

La base de datos únicamente almacenará la referencia del archivo.

No deberán almacenarse archivos binarios directamente en PostgreSQL salvo que exista una justificación técnica.

---

# Transacciones

Toda operación que modifique múltiples tablas deberá ejecutarse dentro de una transacción.

Si una operación falla, todos los cambios deberán revertirse.

---

# Rendimiento

Las consultas deberán optimizarse para minimizar tiempos de respuesta.

Se evitarán:

- Consultas N+1
- Subconsultas innecesarias
- Duplicidad de información
- Consultas sin índices

---

# Migraciones

Todas las modificaciones al esquema deberán realizarse mediante migraciones.

Nunca deberán modificarse migraciones ya aplicadas en producción.

Cada migración deberá representar un único cambio lógico.

---

# Seguridad

No deberán almacenarse:

- Contraseñas en texto plano
- Tokens sin cifrar cuando sean sensibles
- Información confidencial innecesaria

Toda información sensible deberá protegerse mediante los mecanismos adecuados.

---

# Respaldo

La estrategia de respaldo deberá permitir:

- Recuperación completa de la base de datos.
- Recuperación ante errores.
- Restauración de versiones anteriores cuando sea necesario.

---

# Restricciones

No duplicar información.

No utilizar nombres ambiguos.

No utilizar columnas genéricas como:

data

value

info

No almacenar múltiples valores dentro de una sola columna.

No eliminar registros críticos sin una política definida.

---

# Objetivo final

Mantener una base de datos consistente, eficiente y fácil de mantener, capaz de evolucionar junto con el sistema sin comprometer la integridad de la información.