# Arquitectura del proyecto

El sistema sigue una arquitectura cliente-servidor.

El frontend consume una API REST desarrollada en django.

Toda la lógica de negocio se encuentra en la capa de servicios.

La persistencia de datos se realiza mediante PostgreSQL.

## Tecnologías

### Backend

Django

Motivo:

- Framework maduro.
- Excelente sistema de autenticación.
- Ecosistema amplio.
- Escalabilidad para manejo de IA.

---

### Frontend

Flutter

Motivo

- Fácil integración.
- Escalabilidad multiplataforma.

---

### Base de datos

PostgreSQL

Motivo

- Alto rendimiento.
- Soporte para JSONB.