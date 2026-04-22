---
status: APPROVED
feature: ui-design
author: spec-generator
created: 2026-04-21
scope: flutter-ui
---

# Spec: UI & UX Guidelines (Flutter Mobile-First)

> Regla de oro: la interfaz debe sentirse clara, confiable y fácil de usar para una persona no técnica. Esta app no busca densidad extrema ni estética llamativa; busca legibilidad, control y rapidez.

## 1. Sistema de Diseño

### 1.1 Paleta de colores

- **Primario**: `#0C447C`.
- **Superficie clara**: `#F8F9FA`.
- **Texto principal**: `#111827`.
- **Texto secundario**: `#4B5563`.
- **Éxito**: verdes suaves para estados positivos.
- **Alerta**: ámbar o rojo suave para validaciones y errores.

No usar una paleta saturada ni múltiples acentos decorativos.

### 1.2 Tipografía

- Usar la tipografía del sistema o la familia base de Material.
- Evitar fuentes ornamentales.
- Priorizar tamaños legibles; `14` y `16` como base para formularios y listados.

### 1.3 Layout

- Mobile first.
- En móvil, el contenido principal debe caber en una columna clara.
- En tablet y escritorio, se puede usar maestro-detalle o dos columnas.
- Mantener márgenes y paddings moderados.

## 2. Componentes de interfaz

### 2.1 Acciones principales

- Un botón primario por pantalla, con el azul corporativo.
- Las acciones secundarias deben verse claramente como secundarias.
- Los formularios deben tener CTA cortos y directos.

### 2.2 Tarjetas de catálogo

- Cada tarjeta debe resumir el dato importante: nombre, costo, estado y acciones.
- Evitar tarjetas demasiado altas o con información duplicada.

### 2.3 Formulario de edición

- En móvil, abrir como pantalla completa o bottom sheet grande.
- En escritorio, se puede usar panel lateral si no rompe la lectura.
- Los campos deben estar agrupados por intención: identidad, receta, costo, estado.

### 2.4 Estados

- Loading visible y sobrio.
- Empty state con texto útil y una acción clara.
- Error state con mensaje breve y recuperación posible.

## 3. Mapeo de pantallas

| Ruta / Pantalla | UX esperado |
|------------------|-------------|
| Login | Pantalla simple, centrada, con email, contraseña y acceso claro |
| Home / Productos | Buscador principal, tarjetas de productos y acceso rápido a simulación |
| Materias primas | Lista editable con búsqueda, precio actual y categoría |
| Categorías | CRUD simple con control para la categoría `lona` |
| Subproductos | Lista + detalle de receta y costos de fabricación |
| Productos finales | Lista + detalle de componentes, flag `clientProvidesLona` y costo calculado |
| Simulador | Entrada de cantidad y resultado inmediato de costos y materiales |

## 4. Principios de experiencia

- La app debe ser fácil de entender en la primera visita.
- Los textos deben hablar en lenguaje de negocio, no técnico.
- Evitar formularios largos sin agrupación visual.
- Los estados y etiquetas deben ser consistentes en toda la app.
- El flujo principal debe requerir pocos toques: buscar producto, abrir detalle, simular X unidades.

## 5. Accesibilidad y usabilidad

- Tamaños de toque cómodos.
- Contraste suficiente entre texto y superficie.
- Etiquetas visibles siempre que aplique.
- No depender solo del color para explicar estados.
- Mensajes de error concretos y accionables.

## 6. Reglas de estilo visual

- Usar `Card`, `ListTile`, `Chip`, `InputDecoration` limpia y jerarquía visual simple.
- No sobrecargar la UI con adornos.
- Las pantallas deben verse ordenadas y confiables.
- El diseño debe sentirse amable y claro para una usuaria que no sea técnica.

## 7. Patrones recomendados

- Catálogos con búsqueda arriba y tarjetas o lista compacta.
- Formularios con secciones claras y validación inline.
- Detalles con resumen superior y desglose debajo.
- Simulador con resumen visible arriba y materiales desglosados abajo.

## 8. Lo que no debe hacer la UI

- No usar patrones heredados del proyecto anterior ni stepper de cotización.
- No usar componentes decorativos sin función.
- No esconder la información de costo en pantallas secundarias.
- No usar flujos complejos si un formulario simple resuelve el caso.
