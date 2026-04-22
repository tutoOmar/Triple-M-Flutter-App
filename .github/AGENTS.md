# AGENTS.md — cotizador-danos-web (Frontend Angular 19)

> Reglas activas para todos los agentes que trabajen en este repositorio.

Este repositorio es **exclusivo del frontend** (`cotizador-danos-web`). No contiene código Java, Spring Boot, Docker ni base de datos.

---

## Agentes Activos

| Agente | Archivo | Fase |
|--------|---------|------|
| **Orchestrator** | `.github/agents/orchestrator.agent.md` | Coordinación |
| **Spec Generator** | `.github/agents/spec-generator.agent.md` | Especificación (Fase 1) |
| **Frontend Developer** | `.github/agents/frontend-developer.agent.md` | Implementación (Fase 2) |
| **Test Engineer FE** | `.github/agents/test-engineer-frontend.agent.md` | Tests unitarios (Fase 3) |
| **QA Agent** | `.github/agents/qa.agent.md` | Gherkin y UI Risks (Fase 4) |
| **Documentation Agent** | `.github/agents/documentation.agent.md` | Documentación (Fase 5) |

---

## Flujo de Trabajo (ASDD Frontend)

```
[Orchestrator]
      ↓
[1. Spec] → [2. Frontend Developer] → [3. Test Engineer FE] → [4. QA Agent] → [5. Doc Agent]
```

1. **Spec Generator**: Genera `.github/specs/<feature>.spec.md`. Debe tener `status: APPROVED` antes de seguir.
2. **Frontend Developer**: Implementa `models` → `state` → `service` → `component` → `template`.
3. **Test Engineer FE**: Genera tests unitarios (`state service`, `HTTP service`, `component`).
4. **QA Agent**: Genera escenarios Gherkin enfocados en UI/UX y edge cases.
5. **Documentation Agent**: Actualiza README y guías de componentes.

---

## Backends de Referencia

> Las URLs se definen en `src/environments/environment.ts`. Los agentes deben leerlas de allí.
> ⚠️ **Fuente de verdad de endpoints**: `.github/specs/api-contracts.spec.md` — distingue `[REAL]` vs `[PLANEADO]`.

| Servicio | URL local | Variable en `environment.ts` |
|----------|-----------|------------------------------|
| `plataforma-danos-back` | `http://localhost:8080` | `environment.danosBackUrl` |
| `plataforma-core-ohs` | `http://localhost:8081` | `environment.coreOhsUrl` |

### Endpoints REALES — plataforma-danos-back `:8080`

| Método | Endpoint | Servicio Angular | Descripción |
|--------|----------|-----------------|-------------|
| `POST` | `/v1/folios` | `cotizacion.service.ts` | Crear/recuperar folio (idempotente) |
| `PUT` | `/v1/quotes/{folio}/general-info` | `cotizacion.service.ts` | Actualizar datos del asegurado (requiere `version`) |
| `POST` | `/v1/quotes/{folio}/calculate` | `cotizacion.service.ts` | Ejecutar motor de cálculo de primas |

### Endpoints REALES — plataforma-core-ohs `:8081` (stub/mock)

| Método | Endpoint | Servicio Angular | Descripción |
|--------|----------|-----------------|-------------|
| `GET` | `/v1/folios` | `core-ohs.service.ts` | Siguiente número de folio |
| `GET` | `/v1/subscribers` | `core-ohs.service.ts` | Catálogo de suscriptores |
| `GET` | `/v1/agents` | `core-ohs.service.ts` | Catálogo de agentes |
| `GET` | `/v1/business-lines` | `core-ohs.service.ts` | Giros con `claveIncendio` |
| `GET` | `/v1/catalogs/risk-classification` | `core-ohs.service.ts` | Clasificación de riesgo |
| `GET` | `/v1/catalogs/guarantees` | `core-ohs.service.ts` | Garantías tarifables |
| `GET` | `/v1/zip-codes/{zipCode}` | `core-ohs.service.ts` | Info del CP (estado, zona, zonaCatastrófica) |
| `POST` | `/v1/zip-codes/validate` | `core-ohs.service.ts` | Validar existencia de CP |
| `GET` | `/v1/tariffs/incendio` | `core-ohs.service.ts` | Tarifa incendio |
| `GET` | `/v1/tariffs/cat` | `core-ohs.service.ts` | Tarifa catastrófica |
| `GET` | `/v1/tariffs/fhm` | `core-ohs.service.ts` | Tarifa FHM |
| `GET` | `/v1/tariffs/parametros-calculo` | `core-ohs.service.ts` | Parámetros del motor de cálculo |

---

## Documentos que los Agentes Deben Cargar

| Documento | Ruta | Quién lo carga |
|-----------|------|----------------|
| Reglas de Oro | `.github/AGENTS.md` | Todos |
| Contexto general | `.github/copilot-instructions.md` | Todos |
| **Contratos de API (endpoints reales)** | `.github/specs/api-contracts.spec.md` | Frontend Developer, Test Engineer FE |
| Stack y restricciones frontend | `.github/instructions/frontend.instructions.md` | Frontend Developer, Test Engineer FE |
| Arquitectura completa | `ARCHITECTURE.md` | Todos |

---

## Reglas de Oro

### I. Integridad del Código

- **No código no autorizado**: no generar código sin solicitud explícita del usuario.
- **No modificaciones no autorizadas**: no modificar archivos sin aprobación explícita.
- **Preservar la lógica existente**: respetar patrones arquitectónicos y estilo del proyecto.

### II. Reglas Técnicas No Negociables

1. **Standalone Components**: Nunca generar `@NgModule`.
2. **Signals para estado**: `signal()` + `computed()` + `effect()`. No usar `BehaviorSubject` para estado de UI.
3. **Tailwind CSS únicamente**: Sin Angular Material, PrimeNG ni otras librerías de UI.
4. **Versionado optimista**: Todo `PUT`/`PATCH` incluye el campo `version` del signal de estado.
5. **Sin autenticación**: No hay login, guards de auth ni interceptor JWT.
6. **Lazy loading**: `loadComponent` en `app.routes.ts` para cada feature.
7. **Environments**: URLs de backends desde `environment.ts`, nunca hardcodeadas.
8. **No secrets**: Ninguna API key ni credencial en el código fuente.

### III. Clarificación de Requisitos

- Si la solicitud es ambigua o incompleta, detenerse y pedir clarificación antes de proceder.
- No realizar suposiciones; basar todas las acciones en información explícita del usuario.

---

## Comandos de Desarrollo

```bash
npm install          # Instalar dependencias
ng serve             # Dev server → http://localhost:4200
ng build --configuration production
ng test              # Tests unitarios
```
