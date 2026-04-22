---
status: DRAFT
feature: materials
author: spec-generator
created: 2026-04-22
scope: materias primas CRUD
---

# Spec: Materias Primas

## 1. Objetivo

Administrar el catálogo de materias primas usadas por los subproductos.
Cada materia prima tiene nombre, categoría, unidad y precio actual editable manualmente.

## 2. Alcance

Incluye:

- listar materias primas;
- crear materia prima;
- editar materia prima;
- eliminar materia prima;
- buscar por nombre;
- filtrar por categoría;
- mostrar precio actual y unidad.

Excluye:

- inventario físico;
- kardex;
- conversiones de unidades;
- compras y proveedores;
- cálculo de costos en esta pantalla.

## 3. Usuarios y permisos

- `admin`: puede crear, editar y eliminar.
- `operadora`: puede crear, editar y eliminar según el permiso aprobado para este proyecto.

## 4. Dependencias de datos

- colección `materials`;
- colección `materialCategories`;
- `DATA_MODEL.md`;
- `DATA_MODEL.md` para el campo `currentPrice` y `categoryId`.

## 5. UX esperado

- Pantalla tipo catálogo con buscador visible.
- Lista de materias primas ordenada por nombre.
- Formulario simple para crear o editar.
- Campos obligatorios claramente marcados.
- Confirmación antes de eliminar.

## 6. Estado requerido

- listado de materias primas;
- item seleccionado para edición;
- loading de lectura/escritura;
- error de validación;
- error de persistencia;
- filtro activo por categoría.

## 7. Reglas de negocio

- nombre obligatorio;
- categoría obligatoria;
- unidad obligatoria;
- precio actual mayor o igual a cero;
- si una materia prima se usa en recetas existentes, se debe permitir eliminarla solo si la spec funcional lo autoriza; por defecto se prioriza borrado físico permitido por decisión del usuario.

## 8. Casos borde

- nombre vacío;
- precio inválido;
- categoría inexistente;
- listado vacío;
- duplicados de nombre;
- eliminación de un registro usado en recetas.

## 9. Criterios de aceptación

- El catálogo permite crear, editar, listar y eliminar materias primas.
- La búsqueda filtra resultados por nombre.
- El filtro por categoría funciona.
- El formulario valida los campos requeridos.
- La pantalla muestra el precio actual y la unidad de cada materia prima.

## 10. Notas de implementación

- Los datos deben persistirse en Firestore.
- La UI debe ser simple y clara para una usuaria no técnica.
- El módulo debe leer categorías desde `materialCategories`.

## 11. Estrategia de pruebas

- test de creación;
- test de edición;
- test de eliminación;
- test de validación;
- test de búsqueda y filtro;
- test de estado vacío.
