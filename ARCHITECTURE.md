# ARCHITECTURE.md

## Proposito

Este proyecto es una app Flutter + Firebase para control financiero interno de un negocio familiar de manufactura.
El objetivo principal es responder dos preguntas:

1. Cuanto cuesta fabricar cada producto.
2. Cuanto material se necesita para producir X unidades.

No incluye ventas, facturacion, inventario fisico, kardex, merma, lotes, trazabilidad ni aprobaciones.

## Alcance Funcional

La app maneja tres capas de composicion:

- Materias primas.
- Subproductos.
- Productos finales.

Las materias primas tienen precio actual editable manualmente.
Los subproductos se calculan a partir de materias primas y costos fijos de fabricacion.
Los productos finales se calculan a partir de uno o varios subproductos.

Existe una unica variante de negocio:

- Algunos productos tienen el flag `clientePoneLaLona`.
- Cuando esta activo, el calculo excluye de ese producto todos los insumos de categoria `lona` dentro de los subproductos que lo componen.

## Principios De Arquitectura

- Flutter mobile-first con adaptacion responsive para PC.
- Firebase Auth con correo y contrasena.
- Firestore como unica fuente de datos.
- Estructura simple, pensada para uso interno y bajo volumen de datos.
- Sin dependencia de backend propio.
- La logica de calculo vive en la app y se apoya en datos de Firestore.
- Los costos se derivan al vuelo desde los precios actuales de materias primas.
- El proyecto debe ser facil de entender, probar y modificar por un equipo pequeno.

## Stack Tecnico Propuesto

- Flutter.
- Firebase Auth.
- Cloud Firestore.
- flutter_riverpod para estado de aplicacion.
- go_router para navegacion.
- intl para formato de moneda y numeros.
- json_serializable o modelos manuales livianos para serializacion de Firestore.

## Modelo De Capas

### Presentacion

Pantallas, widgets, formularios, busqueda, filtros y dialogos.
La UI debe ser limpia, mobile first y apta para pantallas grandes sin cambiar el flujo principal.

### Aplicacion

Controladores o notifiers por feature para:

- cargar catalogos;
- crear y editar datos;
- ejecutar simulaciones de costo;
- calcular requerimientos de materiales para X unidades;
- manejar estado de carga y error.

### Dominio

Reglas puras del negocio:

- calculo de costo por subproducto;
- calculo de costo por producto final;
- expansion recursiva de materiales necesarios;
- aplicacion del flag `clientePoneLaLona`.

### Datos

Repositorios que leen y escriben en Firestore y autentican con Firebase Auth.
La app no debe conocer detalles de colecciones fuera de esta capa.

## Estructura Recomendada De `lib/`

```text
lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    config/
    errors/
    formatting/
    widgets/
  features/
    auth/
    dashboard/
    materials/
    subproducts/
    products/
    simulation/
```

### Criterios De Organizacion

- Cada feature agrupa sus pantallas, controladores, modelos y repositorios.
- El codigo compartido vive en `core/`.
- La navegacion se define por rutas simples y declarativas.
- La logica de calculo no debe quedar dentro de widgets.

## Flujo De Pantallas

### 1. Login

Autenticacion con correo y contrasena.
Como solo hay dos usuarios internos, el acceso es simple y sin flujos de recuperacion complejos salvo que luego se definan.

### 2. Inicio

Pantalla principal con:

- buscador global de productos;
- listado de productos finales;
- acceso rapido a materias primas y subproductos.

### 3. Producto Final

Detalle del producto con:

- composicion por subproductos;
- costo calculado por unidad;
- simulacion para X unidades;
- desglose de materiales requeridos.

### 4. Subproducto

Detalle del subproducto con:

- materias primas utilizadas;
- costos de manufactura, patinajeje y armado de bolsillos;
- costo por unidad;
- impacto de la variante `clientePoneLaLona` cuando aplique.

### 5. Materias Primas

Catalogo editable con nombre, categoria, unidad y precio actual.

## Reglas De Negocio Para Calculo

### Subproducto

Costo unitario del subproducto =

- suma de cada materia prima utilizada multiplicada por su cantidad;
- mas costo de manufactura;
- mas costo de patinajeje;
- mas costo de armado de bolsillos cuando exista.

### Producto Final

Costo unitario del producto final =

- suma de los costos unitarios de los subproductos multiplicados por su cantidad en la receta.

### Simulacion De X Unidades

Para X unidades:

- multiplicar la receta del producto final por X;
- expandir cada subproducto a sus materias primas;
- acumular cantidades por materia prima;
- aplicar la exclusion de categoria `lona` cuando `clientePoneLaLona` sea verdadero.

## Firebase

### Auth

Se usa Firebase Auth con correo y contrasena.

### Firestore

Firestore guarda:

- usuarios y perfil minimo;
- catalogo de materias primas;
- catalogo de subproductos;
- catalogo de productos finales;
- catalogos auxiliares como categorias.

### Reglas De Seguridad

La primera version debe asumir una app interna con autenticacion obligatoria.
Las reglas deben bloquear acceso a datos sin login y restringir escrituras segun el rol definido en el perfil de usuario.

## Estrategia De Estado

Se recomienda flutter_riverpod porque encaja bien con:

- lectura reactiva de Firestore;
- simulaciones derivadas;
- estado de formularios;
- separacion clara entre UI y logica.

El estado local de pantalla debe ser pequeno y el estado de negocio debe vivir en notifiers o controllers por feature.

## Navegacion

Se recomienda go_router con rutas simples:

- `/login`
- `/home`
- `/products`
- `/products/:id`
- `/subproducts/:id`
- `/materials`

## Estrategia De UI

- Mobile first.
- Buscador visible desde el inicio.
- Acciones criticas a dos taps o menos.
- Sin modo oscuro obligatorio en la primera version.
- Sin librerias pesadas de UI si no son necesarias.

## Estrategia De Calidad

- Tests unitarios para la logica de calculo.
- Tests de widgets para flujos criticos.
- Tests de repositorio contra dobles o emulador cuando aplique.
- La logica de costo debe ser verificable sin depender de widgets.

## Adaptacion Del Flujo `.github`

Se conserva la esencia del flujo ASDD, pero adaptada a Flutter:

1. Spec Generator: genera specs funcionales antes de implementar.
2. Flutter Developer: implementa modelos, repositorios, estado y UI.
3. Test Engineer FE: crea tests unitarios y de widgets.
4. QA Agent: define casos Gherkin de UX y riesgos visuales.
5. Documentation Agent: actualiza arquitectura, modelo de datos y README.

## Decisiones Cerradas Para Esta Version

- Un solo negocio.
- Sin inventario fisico.
- Sin ventas ni facturacion.
- Sin backend propio.
- Sin storage, cloud functions ni offline obligatorio.
- Sin lotes, trazabilidad ni auditoria.
- Sin conversiones de unidades.
- Sin procesos de aprobacion.
