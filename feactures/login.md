
## Objetivo

Permitir al usuario ingresar al sistema

---

## Flujo

Pagina de inicio

↓

Da clic en "iniciar sesión"

↓

Se abre el formulario

↓

Llena la información

↓

Da clic en Iniciar sesión

↓

El sistema valida

↓

Si hay errores los muestra

↓

Si todo es correcto

↓

Se inicia la sesión

↓

Se muestra un mensaje de exito

↓

Se redirecciona a la pagina principal


---

## Validaciones

- El correo  o usuario debe coincidir.
- La contraseña debe de coincidir
- Evitar injecciones sql.
- Evitar ataques por fuerza bruta

---

## Casos especiales

Si el número de intentos supera las 5 veces:
bloquear el inicio de sesión por media hora

Mostrar:

"Haz intentado ingresar al sistema demasiadas veces. Vuelve a intentarlo en 30 min"

---

## Permisos

- Cualquier usuario.

---

## Futuras mejoras

- Implementar autenticación con OAuth2.0