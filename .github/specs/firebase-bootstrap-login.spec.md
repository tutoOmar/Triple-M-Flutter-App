---
status: DRAFT
feature: firebase-bootstrap-login
author: spec-generator
created: 2026-04-22
scope: app bootstrap, Firebase Auth, login and logout
---

# Spec: Firebase Bootstrap + Login

## 1. Objetivo

Configurar la app Flutter para conectarse a Firebase y permitir el acceso inicial con correo y contraseña.
Esta spec cubre el arranque base del proyecto y el acceso autenticado, que es requisito para usar cualquier otra parte de la app.

## 2. Alcance

Incluye:

- configuración inicial de Firebase con `flutterfire configure`;
- inicialización de Firebase en la app;
- login con correo y contraseña;
- logout;
- reglas base de acceso autenticado;
- pantalla inicial de entrada al sistema.

Excluye:

- recuperación de contraseña;
- registro público;
- Storage, Cloud Functions y mensajería;
- configuración de módulos funcionales de negocio.

## 3. Usuarios y permisos

- `admin`: acceso completo a la app.
- `operadora`: acceso a consulta y edición según las reglas de cada módulo funcional.

No existe acceso anónimo.

## 4. Dependencias de datos

- Firebase Auth.
- Firestore.
- `.github/specs/firebase-contracts.spec.md`.
- `DATA_MODEL.md`.

## 5. UX esperado

- Pantalla simple de acceso con correo y contraseña.
- Mensajes de error breves y claros.
- Botón de entrar visible.
- Al autenticar, llevar al catálogo principal de productos.
- Si la sesión existe, entrar directamente sin repetir login.

## 6. Estado requerido

- provider o notifier de autenticación;
- estado de sesión actual;
- loading de login;
- error de autenticación;
- usuario autenticado y rol.

## 7. Reglas de negocio

- El login usa correo y contraseña.
- El logout cierra la sesión y limpia estado local.
- No existe registro público.
- Si el usuario no está autenticado, no puede entrar al resto de la app.
- La app debe fallar de forma controlada si Firebase no está inicializado.

## 8. Casos borde

- credenciales inválidas;
- sesión expirada;
- Firebase no inicializado;
- usuario deshabilitado;
- error de red al autenticar.

## 9. Criterios de aceptación

- La app inicializa Firebase antes de mostrar el contenido principal.
- El usuario puede iniciar sesión con correo y contraseña.
- El usuario puede cerrar sesión.
- La app no permite navegar a módulos protegidos sin autenticación.
- Los errores de autenticación se muestran de forma legible.

## 10. Notas de implementación

- Requiere `firebase_options.dart` generado.
- Debe usar Firebase Auth y Firestore desde el primer arranque.
- La navegación debe redirigir por estado de sesión.

## 11. Estrategia de pruebas

- test de login exitoso;
- test de credenciales inválidas;
- test de logout;
- test de redirección por sesión activa;
- test de estado inicial sin Firebase listo.
