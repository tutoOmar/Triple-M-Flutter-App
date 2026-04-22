# Copilot Instructions — Cotizador de Daños (Frontend Angular 19)

Este repositorio contiene **únicamente** el frontend (`cotizador-danos-web`), una SPA Angular 19 sin backend ni base de datos.

---

## Agentes Disponibles

| Agente | Fase | Archivo |
|--------|------|---------|
| Orchestrator | Coordinación | `.github/agents/orchestrator.agent.md` |
| Spec Generator | 1. Spec | `.github/agents/spec-generator.agent.md` |
| Frontend Developer | 2. Implementación | `.github/agents/frontend-developer.agent.md` |
| Test Engineer FE | 3. Tests unitarios | `.github/agents/test-engineer-frontend.agent.md` |
| QA Agent | 4. QA UI | `.github/agents/qa.agent.md` |
| Documentation Agent | 5. Docs | `.github/agents/documentation.agent.md` |

---

## Flujo de Desarrollo (ASDD Frontend)

```
[Orchestrator] → [Spec Generator] → [Frontend Developer] → [Test Engineer FE] → [QA] → [Doc]
```

1. **Spec**: `spec-generator` crea `.github/specs/<feature>.spec.md` (debe alcanzar `status: APPROVED`).
2. **Implementación**: `frontend-developer` crea models → state (signals) → service → component → template.
3. **Tests**: `test-engineer-frontend` genera pure unit tests para state, servicios HTTP y componentes.
4. **QA**: `qa-agent` genera escenarios Gherkin enfocados en UI y riesgos front-end.
5. **Docs**: `documentation-agent` actualiza README y directrices UI.

---

## Reglas de Oro

1. **Standalone Components**: No generar `@NgModule` bajo ninguna circunstancia.
2. **Signals para estado de UI**: `signal()` + `computed()` + `effect()`. No usar `BehaviorSubject`.
3. **Tailwind CSS**: Sin Angular Material, PrimeNG ni otras librerías de componentes UI.
4. **Versionado optimista**: Todo `PUT`/`PATCH` incluye `version` tomado del signal de estado.
5. **Sin autenticación**: No hay login, guards de auth ni interceptor JWT.
6. **Lazy loading por feature**: Usar `loadComponent` en `app.routes.ts`.
7. **Environments**: URLs de backends siempre desde `src/environments/environment.ts`.

---

## Backends Consumidos

| Servicio | URL base | Uso |
|----------|----------|-----|
| `plataforma-danos-back` | `http://localhost:8080` | API principal del cotizador |
| `plataforma-core-ohs` | `http://localhost:8081` | Catálogos y validación de CP |

> Ver tabla completa de endpoints en `.github/AGENTS.md`.

---

## Definition of Ready (Spec)

Una spec está lista para implementar cuando:
- `status: APPROVED` en el frontmatter
- Tiene definidos: endpoints consumidos, interfaces TypeScript, signals requeridos, comportamiento UI

## Definition of Done (Implementación)

Un feature está "hecho" cuando:
- Componente standalone con lazy loading registrado en `app.routes.ts`
- State service con signals, computed y manejo de `loading`/`error`
- HTTP service con llamadas tipadas desde `core/services/`
- Templates con Tailwind CSS sin inline `style` ni clases arbitrarias
- Manejo de `409` y `404` delegado al interceptor global (`error.interceptor.ts`)
- Sin `console.log` en código de producción

---

## Diccionario de Dominio

| Término | Definición |
|---------|-----------|
| **Folio** (`numeroFolio`) | Identificador de negocio de la cotización (`string`) |
| **Cotización** | Agregado principal: asegurado, ubicaciones y primas |
| **Ubicación** | Bien inmueble asegurable dentro de la cotización |
| **Prima Neta** | Monto del seguro antes de factor comercial (`number`) |
| **Prima Comercial** | Prima neta × factor comercial (`number`) |
| **Giro** | Actividad económica del inmueble |
| **estadoCotizacion** | Estado: `BORRADOR` \| `EN_PROCESO` \| `CALCULADA` |
| **alertasBloqueantes** | Alertas que impiden el cálculo de una ubicación (no bloquean UI) |

**Nomenclatura**: `camelCase` en TypeScript · `kebab-case` en nombres de archivos.
