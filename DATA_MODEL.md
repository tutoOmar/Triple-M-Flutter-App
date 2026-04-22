# DATA_MODEL.md

## Proposito

Este documento define el modelo de datos base para Firestore.
La prioridad es simplicidad: pocas colecciones, relaciones claras y calculo derivado desde datos actuales.

## Reglas Generales Del Modelo

- Firestore es la unica persistencia.
- No se guarda inventario fisico.
- No se guarda kardex.
- El costo no es una fuente de verdad persistida; se calcula a partir de materias primas y recetas.
- Las recetas usan cantidades fijas por unidad.
- No hay conversiones entre unidades.
- La app trabaja con un solo negocio.

## Colecciones Principales

### 1. `users`

Perfil minimo para controlar acceso y rol.

Campos sugeridos:

- `uid` string, mismo valor que Firebase Auth.
- `name` string.
- `email` string.
- `role` string, valores sugeridos: `admin`, `operadora`.Ambos tendran igual acceso a la app, pero el rol puede ser util para futuras restricciones o auditoria.
- `active` bool.
- `createdAt` timestamp.
- `updatedAt` timestamp.



### 2. `materialCategories`

Catalogo pequeno de categorias de materias primas.

Campos sugeridos:

- `name` string.
- `slug` string, por ejemplo `lona`.
- `active` bool.
- `createdAt` timestamp.

Uso:

- clasificar materias primas;
- permitir la regla especial de exclusion de categoria `lona`.

### 3. `materials`

Catalogo de materias primas.

Campos sugeridos:

- `name` string.
- `categoryId` string, referencia logica a `materialCategories`.
- `unit` string, por ejemplo `metro`, `pieza`, `cm`.
- `currentPrice` number.
- `notes` string opcional.
- `active` bool.
- `createdAt` timestamp.
- `updatedAt` timestamp.

Uso:

- fuente para calcular costos de subproductos;
- fuente para saber cuanto material se necesita.

### 4. `subproducts`

Catalogo de subproductos fabricados a partir de materias primas.

Campos sugeridos:

- `name` string.
- `description` string opcional.
- `outputUnit` string, por ejemplo `pieza`, `set`, `panel`.
- `manufacturaCost` number.
- `patinajejeCost` number.
- `armadoBolsillosCost` number, usar `0` si no aplica.
- `active` bool.
- `createdAt` timestamp.
- `updatedAt` timestamp.

Subdocumentos o arreglo embebido recomendado:

- `ingredients[]`.

Estructura de cada ingrediente:

- `materialId` string.
- `quantityPerUnit` number.
- `notes` string opcional.

Uso:

- definir la receta de cada subproducto;
- calcular costo unitario;
- calcular materiales necesarios al expandir una produccion.

### 5. `products`

Catalogo de productos finales.

Campos sugeridos:

- `name` string.
- `description` string opcional.
- `outputUnit` string, por ejemplo `pieza`.
- `clientProvidesLona` bool.
- `active` bool.
- `createdAt` timestamp.
- `updatedAt` timestamp.

Subdocumentos o arreglo embebido recomendado:

- `components[]`.

Estructura de cada componente:

- `subproductId` string.
- `quantityPerUnit` number.
- `notes` string opcional.

Uso:

- definir de que subproductos se compone cada producto final;
- calcular costo unitario final;
- simular produccion de X unidades.

## Modelo Relacional Logico

### `users`

No depende de otras colecciones de negocio.

### `materials`

Cada materia prima pertenece a una categoria.

### `subproducts`

Cada subproducto depende de una lista de materias primas.

No puede depender de otros subproductos.

### `products`

Cada producto final depende de una lista de subproductos.

No depende directamente de materias primas.

## Reglas De Negocio En Datos

### Regla 1: Subproducto Solo Usa Materias Primas

El modelo no permite anidar subproductos dentro de subproductos.

### Regla 2: Producto Final Usa Subproductos

El modelo no permite que un producto final consuma materias primas directamente.

### Regla 3: Flag `clientProvidesLona`

Si el producto final tiene `clientProvidesLona = true`, se excluyen de la simulacion todos los ingredientes cuya materia prima pertenezca a la categoria `lona`.

### Regla 4: Costos Fijos Del Subproducto

Cada subproducto siempre considera:

- `manufacturaCost`;
- `patinajejeCost`;
- `armadoBolsillosCost`.

Si un subproducto no usa armado de bolsillos, ese campo se guarda en `0`.

### Regla 5: Sin Conversiones

Las cantidades se guardan en la unidad elegida para cada materia prima.
La app no convierte entre unidades.

## Ejemplo De Estructura De Documento

### Materia Prima

```json
{
  "name": "Lona 14 oz",
  "categoryId": "lona",
  "unit": "metro",
  "currentPrice": 85.5,
  "active": true
}
```

### Subproducto

```json
{
  "name": "Panel frontal",
  "outputUnit": "pieza",
  "manufacturaCost": 12,
  "patinajejeCost": 4,
  "armadoBolsillosCost": 3,
  "ingredients": [
    {
      "materialId": "lona_14_oz",
      "quantityPerUnit": 1.2
    },
    {
      "materialId": "hilo_negro",
      "quantityPerUnit": 0.15
    }
  ],
  "active": true
}
```

### Producto Final

```json
{
  "name": "Maletin ejecutivo",
  "outputUnit": "pieza",
  "clientProvidesLona": true,
  "components": [
    {
      "subproductId": "panel_frontal",
      "quantityPerUnit": 1
    },
    {
      "subproductId": "cuerpo_principal",
      "quantityPerUnit": 1
    }
  ],
  "active": true
}
```

## Calculo Derivado

### Costo Unitario De Un Subproducto

```
costoSubproducto =
  suma(ingrediente.quantityPerUnit * material.currentPrice)
  + manufacturaCost
  + patinajejeCost
  + armadoBolsillosCost
```

Si el producto final activo la variante `clientProvidesLona`, se omiten los ingredientes cuyo `material.categoryId` corresponda a `lona`.

### Costo Unitario De Un Producto Final

```
costoProducto = suma(subproducto.costoUnitario * componente.quantityPerUnit)
```

### Materiales Necesarios Para X Unidades

1. Tomar la receta del producto final.
2. Multiplicar cada componente por X.
3. Expandir cada subproducto a sus materias primas.
4. Acumular por `materialId`.
5. Omitir materiales de categoria `lona` cuando aplique la variante.

## Campos De Estado Recomendados

Aunque la app no maneja aprobaciones ni auditoria, si conviene guardar estos metadatos:

- `active` para ocultar registros sin borrarlos.
- `createdAt` para orden y mantenimiento.
- `updatedAt` para saber cuando cambio un catalogo.

No se consideran obligatorios para el calculo, pero ayudan a operar el catalogo con seguridad.

## Consultas Mas Frecuentes

- listar productos activos para buscar rapidamente;
- obtener detalle de un producto con sus subproductos;
- leer materias primas por `materialId` para calcular costos;
- buscar materiales por categoria `lona`;
- editar precio actual de una materia prima;
- simular costo de X unidades desde un producto final.

## Lo Que No Se Modela En Esta Version

- inventario fisico;
- kardex;
- lotes;
- trazabilidad;
- compras;
- ventas;
- facturacion;
- roles complejos;
- aprobaciones;
- versionado historico de recetas;
- conversiones de unidades;
- almacenamiento de archivos.
