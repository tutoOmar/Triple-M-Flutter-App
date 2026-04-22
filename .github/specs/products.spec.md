---
status: DRAFT
feature: products
author: spec-generator
created: 2026-04-22
scope: productos finales CRUD + componentes + clientProvidesLona
---

# Spec: Productos Finales

## 1. Objetivo

Administrar productos finales que se componen de uno o varios subproductos.
Este módulo debe calcular el costo unitario del producto y respetar la variante `clientProvidesLona`.

## 2. Alcance

Incluye:

- listar productos finales;
- crear producto final;
- editar producto final;
- eliminar producto final;
- gestionar componentes subproducto;
- activar o desactivar `clientProvidesLona`;
- calcular costo unitario por producto;
- mostrar desglose por subproducto.

Excluye:

- uso directo de materias primas en productos finales;
- inventario;
- ventas;
- facturación.

## 3. Usuarios y permisos

- `admin`: puede crear, editar y eliminar.
- `operadora`: puede crear, editar y eliminar según el permiso acordado para este proyecto.

## 4. Dependencias de datos

- colección `products`;
- colección `subproducts`;
- colección `materials` para el cálculo derivado;
- colección `materialCategories` para la variante `lona`.

## 5. UX esperado

- Pantalla principal con catálogo de productos y buscador.
- Detalle con composición, costo y simulación rápida.
- El flag `clientProvidesLona` debe verse claramente en edición y detalle.
- El costo debe estar visible desde el listado o al menos desde el detalle sin navegación adicional compleja.

## 6. Estado requerido

- listado de productos;
- producto seleccionado;
- componentes en edición;
- loading;
- error;
- validaciones;
- costo calculado;
- desglose por subproducto.

## 7. Reglas de negocio

- un producto final usa solo subproductos;
- cada subproducto aparece una sola vez por producto;
- `clientProvidesLona=true` excluye de todos los subproductos las materias primas cuya categoría sea `lona`;
- el costo del producto se calcula a partir de los costos unitarios de sus subproductos;
- se permiten cantidades decimales si el dominio lo requiere;
- no persistir el costo como fuente de verdad.

## 8. Casos borde

- producto sin componentes;
- componente duplicado;
- subproducto inexistente;
- flag `clientProvidesLona` activo con subproductos que no usan lona;
- receta con subproductos vacíos;
- costo total cero.

## 9. Criterios de aceptación

- La pantalla permite crear, editar, listar y eliminar productos finales.
- El producto final solo acepta subproductos como componentes.
- El flag `clientProvidesLona` modifica el cálculo como se espera.
- El costo unitario se calcula automáticamente.
- El buscador filtra productos.

## 10. Notas de implementación

- El módulo debe usar los costos actuales de los subproductos y, a su vez, estos dependen de materias primas.
- La UI debe mostrar un resumen claro del producto y su cálculo.

## 11. Estrategia de pruebas

- test de creación;
- test de edición;
- test de eliminación;
- test de validación de componentes;
- test de cálculo con y sin `clientProvidesLona`;
- test de búsqueda.
