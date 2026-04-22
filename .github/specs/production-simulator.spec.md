---
status: DRAFT
feature: production-simulator
author: spec-generator
created: 2026-04-22
scope: simulador de producción por X unidades
---

# Spec: Simulador de Producción

## 1. Objetivo

Calcular cuánto cuesta producir X unidades de un producto final y cuánto material se requiere.
El simulador debe expandir el producto hacia subproductos y materias primas.

## 2. Alcance

Incluye:

- elegir un producto final;
- ingresar cantidad X;
- calcular costo total;
- calcular costo unitario;
- calcular materiales requeridos;
- mostrar desglose por subproducto y materia prima;
- aplicar la regla `clientProvidesLona`.

Excluye:

- inventario real;
- compras;
- ventas;
- guardar resultados históricos;
- exportación PDF o imagen.

## 3. Usuarios y permisos

- `admin`: puede usar el simulador.
- `operadora`: puede usar el simulador.

## 4. Dependencias de datos

- colección `products`;
- colección `subproducts`;
- colección `materials`;
- colección `materialCategories`;
- `DATA_MODEL.md`.

## 5. UX esperado

- Pantalla simple desde el catálogo de productos.
- Entrada clara para X unidades.
- Resultado inmediato tras ejecutar el cálculo.
- Resumen superior con costo total y costo unitario.
- Desglose posterior por subproducto y por materia prima.

## 6. Estado requerido

- producto seleccionado;
- cantidad X;
- loading;
- error;
- costo total;
- costo unitario;
- materiales agregados;
- desglose por subproducto;
- estado de cálculo vacío o incompleto.

## 7. Reglas de negocio

- el simulador toma un producto final como entrada;
- X debe ser mayor que cero;
- el cálculo multiplica las cantidades de la receta del producto final por X;
- cada subproducto se expande a sus materias primas;
- se acumulan materiales por materia prima;
- la categoría `lona` se excluye cuando el producto tiene `clientProvidesLona=true`;
- el costo final es la suma de los costos unitarios de los subproductos multiplicados por sus cantidades.

## 8. Casos borde

- X vacío o cero;
- producto sin componentes;
- subproducto sin ingredientes;
- materia prima sin precio;
- flag `clientProvidesLona` activo sin materias primas `lona`;
- cálculo con cantidades decimales.

## 9. Criterios de aceptación

- El usuario puede simular X unidades de un producto final.
- La pantalla muestra costo total, costo unitario y materiales requeridos.
- El simulador aplica correctamente la exclusión de `lona`.
- El desglose por subproducto y materia prima es visible.
- El usuario recibe validación si X no es válida.

## 10. Notas de implementación

- Este módulo no persiste el resultado; solo calcula en pantalla.
- El cálculo debe basarse en los datos actuales de Firestore.
- El acceso puede venir desde el detalle de producto o desde una pantalla dedicada.

## 11. Estrategia de pruebas

- test de cálculo exitoso;
- test de cantidad inválida;
- test de exclusión de lona;
- test de desglose por materiales;
- test de producto sin componentes;
- test de estado vacío.
