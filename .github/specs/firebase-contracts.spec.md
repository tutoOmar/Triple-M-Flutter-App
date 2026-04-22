---
status: APPROVED
feature: firebase-contracts
author: spec-generator
created: 2026-04-21
scope: Firebase Auth + Cloud Firestore
---

# Spec: Firebase Contracts — Auth, Firestore y Configuración

## 1. Propósito

Este documento es la fuente de verdad para la configuración base de Firebase y para las colecciones Firestore que usa la app.
Toda spec funcional debe apoyarse en este contrato junto con `ARCHITECTURE.md` y `DATA_MODEL.md`.

## 2. Firebase Auth

### Método de autenticación

- Correo y contraseña.

### Usuarios del sistema

- `admin`.
- `operadora`.

### Reglas generales

- No existe registro público abierto.
- La creación de cuentas iniciales se hace de forma controlada por el negocio.
- La spec de login debe contemplar acceso, cierre de sesión y recuperación de contraseña solo si se aprueba explícitamente.

## 3. Cloud Firestore

### Colecciones principales

| Colección | Uso |
|-----------|-----|
| `users` | Perfil de usuario y rol |
| `materialCategories` | Categorías de materias primas |
| `materials` | Catálogo de materias primas y precios actuales |
| `subproducts` | Recetas intermedias y costos de fabricación |
| `products` | Productos finales y componentes |

### Convenciones

- IDs legibles cuando sea posible.
- Campos en `camelCase`.
- Fechas en `Timestamp` de Firestore.
- No guardar costos calculados como fuente de verdad obligatoria; solo datos base.

## 4. Reglas de permisos

### Baseline

- Usuario autenticado: puede leer la app según su rol.
- `admin`: puede crear, editar y desactivar catálogos.
- `operadora`: puede consultar catálogos y ejecutar simulaciones; la capacidad de escritura debe definirse en cada spec funcional si aplica.

### Principios

- Ninguna colección debe ser accesible sin autenticación.
- No usar reglas complejas innecesarias; preferir reglas claras y mantenibles.

## 5. Campos compartidos recomendados

- `active` para ocultar sin borrar.
- `createdAt` para registro de creación.
- `updatedAt` para mantenimiento.
- `createdBy` y `updatedBy` solo si la spec funcional lo requiere.

## 6. Configuración inicial de Firebase

- La app debe inicializarse con `flutterfire configure`.
- Se debe generar `firebase_options.dart`.
- Las credenciales o claves nunca se escriben manualmente en widgets.
- La app debe fallar de forma controlada si Firebase no está inicializado.

## 7. Lo que no cubre este contrato

- Storage.
- Cloud Functions.
- Mensajería push.
- Analítica.
- Modo offline obligatorio.
- Bases de datos externas o backend propio.
