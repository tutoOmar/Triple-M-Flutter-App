---
status: APPROVED
feature: material-categories
author: spec-generator
created: 2026-04-22
scope: categorías de materias primas CRUD simple
---

# Spec: Categorías de Materias Primas

## 1. Objetivo

Administrar las categorías que clasifican a las materias primas.
Estas categorías sirven para agrupar y aplicar reglas especiales, incluyendo la categoría `lona`.

## 2. Alcance

Incluye:

- listar categorías;
- crear categoría;
- editar categoría;
- eliminar categoría;
- activar o desactivar categoría si se necesita ocultarla.

Excluye:

- jerarquías de categorías;
- múltiples niveles;
- asignación avanzada por reglas.

## 3. Usuarios y permisos

- `admin`: puede crear, editar y eliminar.
- `operadora`: puede gestionar categorías según el permiso acordado para este proyecto.

## 4. Dependencias de datos

- colección `materialCategories`;
- relación lógica desde `materials.categoryId`.

## 5. UX esperado

- Lista compacta de categorías.
- Formulario corto con nombre y estado.
- La categoría `lona` debe verse claramente identificada si existe.

## 6. Estado requerido

- lista de categorías;
- categoría seleccionada;
- loading;
- error;
- validación de nombre.

## 7. Reglas de negocio

- nombre obligatorio;
- nombre único recomendado;
- la categoría `lona` puede existir como categoría normal, pero debe estar claramente soportada por el sistema;
- si una categoría está asociada a materias primas, no se debe borrar sin una decisión explícita de la app.

## 8. Casos borde

- nombre duplicado;
- categoría vacía;
- categoría usada por materias primas;
- lista vacía.

## 9. Criterios de aceptación

- La pantalla permite crear, editar, listar y eliminar categorías.
- La categoría `lona` está disponible para clasificar materias primas.
- El formulario valida el nombre.
- La lista refleja cambios sin recargar manualmente.

## 10. Notas de implementación

- Firestore debe ser la fuente de verdad.
- Este módulo no calcula costos; solo clasifica datos.

## 11. Estrategia de pruebas

- test de creación;
- test de edición;
- test de eliminación;
- test de validación de nombre;
- test de estado vacío.
