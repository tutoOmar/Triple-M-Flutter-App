---
status: APPROVED
feature: ui-design
author: spec-generator
created: 2026-04-20
scope: application
---

# Spec: UI & UX Guidelines (Design System B2B)

> **Regla de Oro**: Todos los agentes de frontend deben aplicar estas directrices exactas y **NO** diseñar interfaces decorativas o con componentes arbitrarios. Este proyecto B2B demanda densidad, limpieza y seriedad profesional.

## 1. Sistema de Diseño (B2B Corporativo)

El sistema prioriza la alta densidad de información, contraste claro y elementos utilitarios sobre adornos decorativos.

### 1.1 Paleta de Colores

- **Primario**: `#0C447C` (Azul corporativo oscuro) — usado para Headers, botones principales (llenos), y bordes activos en stepper.
- **Fondos de Superficie**: `#F8F9FA` (Gris sutil) — usado como fondo principal de las pantallas y detrás de las tarjetas para dar contraste sin saturar la vista.
- **Grises (Tipografía)**: Tailwind default `gray-900` para títulos, `gray-600` para descripciones o labels de formularios.
- **Alertas / Estados**:
  - `Verde (exito)`: Tailwind `green-100` bg, `green-800` text (para badges como "Calculable").
  - `Naranja/Rojo (error/alerta)`: Tailwind `orange-100`/`red-100` bg (para "Incompleta" o badge de "No calculable").

> Nota: No existen colores secundarios o acentos vibrantes (pink, purple). Se mantiene monocromático + azul primario.

### 1.2 Tipografía

- Usa la tipografía de **sistema por defecto** (`font-sans` en Tailwind). No instalar fuentes externas (Google Fonts).
- Fomentar el uso de `text-sm` como tamaño de texto base en pantallas densas (tablas, formularios largos).

### 1.3 Densidad

- Margins y paddings (espacios) deben ser compactos. **NO** utilices padding enormes como `p-10`. Prefiere `p-3`, `p-4`, `gap-3`. Form labels deben estar pegados al respectivo input (`gap-1`).

---

## 2. Componentes Reutilizables y UX

### 2.1 Progress Stepper

- **Posición**: Presente en la parte superior en todas las rutas `/quotes/:folio/*`.
- **Apariencia**: Estilo compacto. El paso actual debe destacar con borde y texto de color `#0C447C` sólido, el fondo en blanco. Los pasos ya terminados deben mostrar su número completado pero atenuados.
- **Comportamiento**: Un click en la navegación del propio stepper debería ser la forma principal de navegar entre vistas. 

### 2.2 Botones de Acción (Formularios)

- **Atrás**: Botón contorneado o transparente (`border`, `text-gray-600`).
- **Avanzar / Siguiente**: Botón delineado (outline) o secundario, permitiendo al usuario avanzar al siguiente paso.
- **Botón CALCULAR PRIMAS**:
  - **Exclusivo del paso final** (`/quotes/:folio/terms-and-conditions`). No debe aparecer en los pasos intermedios de formulario o ubicaciones. 
  - Estilo estelar (Solid background `#0C447C`, text white). Es la acción final.

### 2.3 Formularios Maestros-Detalles (Ubicaciones)

Para el manejo de la colección de ubicaciones (`/quotes/:folio/locations`):

- **Listado (Master)**: Uso de "Cards" o Tarjetas apiladas. Cada card mostrará un sumario de la ubicación: CP, Ciudad, número de garantías prendidas y los Badges de Estado (Calculable, Incompleta, Alertas).
- **Editor / Formulario (Detalle)**: Al pulsar "Editar" o "Agregar Ubicación", NO navegar a otra ruta o cambiar la vista. **Abrir un Panel Lateral (Side Drawer / Slide-over) a la derecha de la pantalla.**
  - Esto asegura que el usuario no pierda el contexto del listado.
  - El drawer contendrá el formulario denso para ingresar el `codigoPostal`, el evento blur para autocompletar, selectores como uso o tipo constructivo (cuando aplique), y toggles múltiples para prender/apagar `garantias`.

### 2.4 Comportamiento de Toggles (Switch)

Para la pantalla `/quotes/:folio/technical-info` de "Coberturas globales" (o selección dentro de Ubicaciones):
- Usar el patrón base de checkbox estilizado como Switch de Tailwind con un label de texto "Activo" / "Inactivo". Color azul (`bg-[#0C447C]`) si está prendido.

---

## 3. Mapeo de Rutas a UX Esperado

| Ruta | Visual y UX |
|------|-----------|
| `/cotizador` | Tarjeta blanca centrada sobre gris, un input grande para Folio, botones para crear o abrir. Simpleza extrema. |
| `/general-info` | Formulario en grid de 2 a 3 columnas. Botón flotante inferior para guardar versión y continuar a ubicaciones. |
| `/locations` | Layout de 2 columnas donde proceda: Lista scrollable a la izquierda con tarjetas de sumario. Panel Lateral Deslizante (drawer) para editar a la derecha. Arriba a la derecha: un botón "+ Agregar Ubicación". |
| `/technical-info` | Lista vertical de switches (Toggles) para coberturas. Grid sencillo tipo opciones de sistema. |
| `/terms-and-conditions` | Layout partido: Cuadro resaltado con subtotales (Neta, Comercial, Folio ID). Inferior: Acordeón o Lista detallando prima aportada por cada Ubicación. Abajo a la derecha: **El Botón `[ Calcular ]`** en Azul Primario sólido. |

---

## 4. Lineamientos de Tailwind a Utilizar

Para estandarizar el look primario:
```html
<!-- Azul primario B2B -> text-[#0C447C] bg-[#0C447C] -->
<button class="bg-[#0C447C] text-white px-4 py-2 rounded-md hover:bg-[#08305A] transition-colors text-sm font-medium">
  Calcular primas
</button>

<!-- Badges (Estado Calculable) -->
<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
  Calculable
</span>
```
`tailwind.config.js` deberá tener bajo theme el `colors.primary: '#0C447C'`.
