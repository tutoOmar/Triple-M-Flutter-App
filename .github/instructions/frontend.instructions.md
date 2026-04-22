---
applyTo: "src/**/*.ts,src/**/*.html"
---

> **Scope**: Se aplica a todo el código frontend en `src/` — Angular 19 Standalone, TypeScript estricto, Tailwind CSS.

# Instrucciones para Frontend (Angular 19 — Standalone + Signals)

## Stack Fijo (No Negociable)

- **Angular 19** con **Standalone Components** — sin NgModules
- **TypeScript strict** (`"strict": true` en `tsconfig.json`)
- **Angular Signals** para todo estado de UI: `signal()`, `computed()`, `effect()`
- **RxJS** solo para `HttpClient` (llamadas HTTP). No usar para estado de UI.
- **Tailwind CSS v3** para estilos — sin Angular Material, PrimeNG ni otras librerías
- `HttpClient` configurado con `provideHttpClient(withInterceptors([...]))` en `app.config.ts`
- Router con `provideRouter(routes)` y lazy loading por feature

## Estructura de Archivos

```
src/app/
├── app.config.ts                   ← providers: router, httpClient, interceptors
├── app.routes.ts                   ← rutas con loadComponent (lazy)
├── core/
│   ├── interceptors/
│   │   └── error.interceptor.ts    ← interceptor funcional de errores HTTP
│   └── services/
│       ├── cotizacion.service.ts   ← :8080
│       └── core-ohs.service.ts     ← :8081
├── shared/
│   ├── models/                     ← interfaces TypeScript del dominio
│   └── components/                 ← componentes reutilizables standalone
└── features/
    ├── cotizador/
    ├── general-info/
    ├── locations/
    ├── technical-info/
    └── terms-and-conditions/
```

## Patron de Estado con Signals

Cada feature tiene su propio `*.state.ts` con `@Injectable({ providedIn: 'root' })`:

```typescript
@Injectable({ providedIn: 'root' })
export class FeatureState {
  private _data   = signal<Cotizacion | null>(null);
  private _loading = signal(false);
  private _error   = signal<string | null>(null);

  readonly data    = this._data.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error   = this._error.asReadonly();
  readonly isReady = computed(() => this._data() !== null && !this._loading());
}
```

**Regla**: Nunca exponer el signal mutable fuera del state service.

## Patrón de Lazy Loading

```typescript
// app.routes.ts
{
  path: 'quotes/:folio/general-info',
  loadComponent: () =>
    import('./features/general-info/general-info.component')
      .then(m => m.GeneralInfoComponent)
}
```

## Interceptor Funcional de Errores

```typescript
// error.interceptor.ts — interceptor funcional (no clase)
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req).pipe(
    catchError((err: HttpErrorResponse) => {
      console.error(`[HTTP Error] ${req.url}`, err.status);
      // lógica por código de error...
      return throwError(() => err);
    })
  );
};
```

## Versionado Optimista

Toda operación `PUT`/`PATCH` debe incluir `version` en el body:

```typescript
// Tomar la version del signal de estado
const version = this.state.cotizacion()?.version ?? 0;
this.cotizacionService.updateGeneralInfo(folio, version, payload).subscribe();
```

- `409 Conflict` → mostrar mensaje: *"La cotización fue modificada por otro proceso. Por favor recarga."*
- `404 Not Found` → redirigir a `/cotizador`

## Tailwind CSS y Sistema de Diseño

- Toda la interfaz sigue las guías descritas en **`.github/specs/ui-design.spec.md`**.
- El estilo es corporativo B2B: máxima densidad de información, bordes limpios, sin adornos excesivos. Usar paddings pequeños como `p-2` o `p-3`, y tipografías densas (`text-sm`).
- El color **primario es `#0C447C`**. Toda acción principal o elemento guía destacado utilizará este color (vía configuración `primary` en `tailwind.config.js`). 
- Usar clases utilitarias de Tailwind directamente en templates HTML.
- No crear archivos CSS por componente salvo para animaciones o estilos imposibles con Tailwind.
- La purga de estilos no usados se realiza automáticamente al compilar.

## Validación de Código Postal (ubicaciones)

Al evento `blur` del campo `codigoPostal`:
1. Llamar `CoreOhsService.getZipCode(cp)` → `GET /v1/zip-codes/{cp}`
2. Si válido: autocompletar `estado`, `municipio`, `colonia`, `ciudad`, `zonaCatastrofica` via signals o FormGroup.
3. Si inválido: mostrar error inline bajo el campo. No bloquear formulario completo.

## Restricciones

- NO generar NgModules.
- NO usar BehaviorSubject para estado de UI.
- NO instalar librerías de componentes (Angular Material, PrimeNG, etc.).
- NO crear pantalla de login, guards de autenticación ni interceptor JWT.
- NO hacer referencia a código de backend Java en este repositorio.
- Los URLs de los backends vienen de `environment.ts`, NUNCA hardcodeados.

---

> Ver `ARCHITECTURE.md` en la raíz del repositorio para la arquitectura completa, contratos de API y reglas de UI.
