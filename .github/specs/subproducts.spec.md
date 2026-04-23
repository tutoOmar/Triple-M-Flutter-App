---
status: IMPLEMENTED
feature: subproducts
author: spec-generator
created: 2026-04-22
scope: subproductos CRUD + receta con ingredientes
---

# Spec: Subproductos

## 1. Objetivo

Administrar subproductos que se construyen solo a partir de materias primas.
Cada subproducto define su receta y sus costos fijos de fabricación.

## 2. Alcance

Incluye:

- listar subproductos;
- crear subproducto;
- editar subproducto;
- eliminar subproducto;
- gestionar ingredientes de la receta;
- calcular costo unitario del subproducto;
- mostrar desglose de materiales y costos.

Excluye:

- subproductos dependientes de otros subproductos;
- inventario;
- trazabilidad;
- lotes;
- merma.

## 3. Usuarios y permisos

- `admin`: puede crear, editar y eliminar.
- `operadora`: puede crear, editar y eliminar según el permiso acordado para este proyecto.

## 4. Dependencias de datos

- colección `subproducts`;
- colección `materials`;
- colección `materialCategories`;
- `DATA_MODEL.md`.

## 5. UX esperado

- Lista de subproductos con costo calculado visible.
- Editor de receta claro y usable.
- Sección de costos fijos separada de los ingredientes.
- Resumen de costo por subproducto antes de guardar.

## 6. Estado requerido

- listado de subproductos;
- subproducto seleccionado;
- ingredientes en edición;
- loading;
- error;
- validaciones por ingrediente;
- costo calculado en tiempo real.

## 7. Reglas de negocio

- un subproducto solo usa materias primas;
- cada materia prima aparece una sola vez por receta;
- cantidades decimales permitidas;
- costos de manufactura, paginaje y armado de bolsillos siempre presentes;
- armado de bolsillos puede ser cero si no aplica;
- el costo unitario se calcula automáticamente;
- si una materia prima pertenece a la categoría `lona`, puede ser excluida más adelante por el simulador del producto final.

## 8. Casos borde

- receta vacía;
- ingrediente duplicado;
- cantidad inválida;
- materia prima eliminada;
- costo de fabricación cero;
- subproducto sin armado de bolsillos.

## 9. Criterios de aceptación

- La pantalla permite crear, editar, listar y eliminar subproductos.
- La receta solo acepta materias primas.
- El costo del subproducto se calcula automáticamente.
- El formulario valida ingredientes y costos.
- La lista muestra el costo unitario de cada subproducto.

## 10. Notas de implementación

- El cálculo debe basarse en el precio actual de cada materia prima.
- No persistir el costo calculado como fuente de verdad.
- La UI debe mostrar el desglose de forma clara para una usuaria no técnica.

## 11. Estrategia de pruebas

- test de creación;
- test de edición;
- test de eliminación;
- test de validación de ingredientes;
- test de cálculo unitario;
- test de estado vacío.
