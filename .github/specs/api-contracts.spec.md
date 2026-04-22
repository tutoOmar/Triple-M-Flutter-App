---
status: APPROVED
feature: api-contracts
author: spec-generator
created: 2026-04-20
scope: core/services — cotizacion.service.ts + core-ohs.service.ts
---

# Spec: Contratos de API — Endpoints Implementados

> **Regla de Oro**: Este documento es la **fuente de verdad** sobre qué endpoints
> existen realmente en los backends. El `frontend-developer` y el `test-engineer-frontend`
> DEBEN leer este archivo antes de generar o testear cualquier servicio HTTP.
>
> ⚠️ **Endpoints marcados como `[PLANNADO]` NO están implementados**. No generar
> código que los consuma hasta que aparezcan en este documento como `[REAL]`.

---

## 1. Backends

| Servicio | URL base (environment) | Variable en `environment.ts` |
|----------|------------------------|------------------------------|
| `plataforma-danos-back` | `http://localhost:8080` | `environment.danosBackUrl` |
| `plataforma-core-ohs` | `http://localhost:8081` | `environment.coreOhsUrl` |

---

## 2. plataforma-danos-back — `:8080`

### 2.1 Endpoints REALES (implementados)

| Estado | Método | Endpoint | Descripción |
|--------|--------|----------|-------------|
| `[REAL]` | `POST` | `/v1/folios` | Crear o recuperar folio. **Idempotente**: si `numeroFolio` ya existe, retorna 200 con el objeto existente. |
| `[REAL]` | `PUT` | `/v1/quotes/{folio}/general-info` | Actualizar datos generales del asegurado. Requiere `version` en el body. |
| `[REAL]` | `POST` | `/v1/quotes/{folio}/calculate` | Ejecutar motor de cálculo de primas. Cambia `estadoCotizacion` a `CALCULADA`. |

### 2.2 Endpoints PLANEADOS (NO implementados — no consumir)

| Estado | Método | Endpoint |
|--------|--------|----------|
| `[PLANEADO]` | `GET` | `/v1/quotes/{folio}/general-info` |
| `[PLANEADO]` | `GET` | `/v1/quotes/{folio}/locations` |
| `[PLANEADO]` | `PUT` | `/v1/quotes/{folio}/locations` |
| `[PLANEADO]` | `PATCH` | `/v1/quotes/{folio}/locations/{indice}` |
| `[PLANEADO]` | `GET` | `/v1/quotes/{folio}/locations/layout` |
| `[PLANEADO]` | `PUT` | `/v1/quotes/{folio}/locations/layout` |
| `[PLANEADO]` | `GET` | `/v1/quotes/{folio}/locations/summary` |
| `[PLANEADO]` | `GET` | `/v1/quotes/{folio}/state` |
| `[PLANEADO]` | `GET` | `/v1/quotes/{folio}/coverage-options` |
| `[PLANEADO]` | `PUT` | `/v1/quotes/{folio}/coverage-options` |

---

## 3. plataforma-core-ohs — `:8081`

### 3.1 Endpoints REALES (implementados — stub/mock)

Todos los endpoints de `core-ohs` están implementados como fixtures JSON (mock).

| Estado | Método | Endpoint | Descripción |
|--------|--------|----------|-------------|
| `[REAL]` | `GET` | `/v1/folios` | Retorna el siguiente número de folio disponible. |
| `[REAL]` | `GET` | `/v1/subscribers` | Catálogo de suscriptores (aseguradoras). |
| `[REAL]` | `GET` | `/v1/agents` | Catálogo de agentes. |
| `[REAL]` | `GET` | `/v1/business-lines` | Giros comerciales con `claveIncendio` incluida. |
| `[REAL]` | `GET` | `/v1/catalogs/risk-classification` | Clasificación de riesgo. |
| `[REAL]` | `GET` | `/v1/catalogs/guarantees` | Catálogo de garantías tarifables. |
| `[REAL]` | `GET` | `/v1/zip-codes/{zipCode}` | Info del CP: `estado`, `municipio`, `colonia`, `ciudad`, `zonaCatastrofica`. |
| `[REAL]` | `POST` | `/v1/zip-codes/validate` | Validar si un CP existe. Retorna `{ valid: boolean }`. |
| `[REAL]` | `GET` | `/v1/tariffs/incendio` | Tarifa de incendio. |
| `[REAL]` | `GET` | `/v1/tariffs/cat` | Tarifa catastrófica. |
| `[REAL]` | `GET` | `/v1/tariffs/fhm` | Tarifa FHM (fenómenos hidrometeorológicos). |
| `[REAL]` | `GET` | `/v1/tariffs/parametros-calculo` | Parámetros del motor de cálculo. |

---

## 4. Formato Estándar de Respuesta

Todos los endpoints retornan `ApiResponse<T>`:

```typescript
// shared/models/api-response.model.ts
export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message: string;
  timestamp: string;        // ISO-8601
}
```

Para errores se usa `ProblemDetail` (RFC 7807):

```typescript
// shared/models/problem-detail.model.ts
export interface ProblemDetail {
  type: string;             // URI del tipo de error
  title: string;            // Título legible
  status: number;           // Código HTTP
  detail: string;           // Descripción del error
  instance: string;         // URI de la solicitud
  errorCode?: string;       // Código interno (ej: FOLIO_NOT_FOUND)
}
```

---

## 5. Tabla de Códigos de Error

| HTTP | `errorCode` | Causa | Acción en UI |
|------|-------------|-------|--------------|
| `400` | `VALIDATION_ERROR` | Datos del request inválidos | Mostrar detalle del error bajo el campo correspondiente |
| `400` | `FOLIO_ALREADY_CALCULADA` | Intentar editar un folio ya calculado | Toast de advertencia |
| `404` | `FOLIO_NOT_FOUND` | `numeroFolio` no existe | Redirigir a `/cotizador` (interceptor) |
| `404` | `ZIP_CODE_NOT_FOUND` | CP no registrado en `core-ohs` | Error inline bajo campo `codigoPostal` |
| `409` | `VERSION_CONFLICT` | Versionado optimista: `version` desactualizada | Toast: *"La cotización fue modificada. Por favor recarga."* |
| `503` | `CORE_OHS_UNAVAILABLE` | `core-ohs` no responde | Toast: *"Servicio no disponible. Intente más tarde."* |

---

## 6. Contratos por Endpoint

### 6.1 `POST /v1/folios` — Crear/Recuperar Folio

**Servicio**: `cotizacion.service.ts`

**Request body**:
```typescript
export interface CreateFolioRequest {
  numeroFolio: string;    // Identificador de negocio. Obtener de GET /v1/folios (core-ohs)
}
```

**Response** (`ApiResponse<FolioResponse>`):
```typescript
export interface FolioResponse {
  numeroFolio: string;
  estadoCotizacion: 'BORRADOR' | 'EN_PROCESO' | 'CALCULADA';
  version: number;
  createdAt: string;      // ISO-8601
}
```

**Comportamiento de idempotencia**:
- Si `numeroFolio` ya existe → retorna `200 OK` con el folio existente (no crea duplicado).
- Si `numeroFolio` no existe → retorna `201 Created` con el nuevo folio.

---

### 6.2 `PUT /v1/quotes/{folio}/general-info` — Actualizar Info General

**Servicio**: `cotizacion.service.ts`

**Path param**: `folio: string` (el `numeroFolio`)

**Request body**:
```typescript
export interface GeneralInfoRequest {
  version: number;              // OBLIGATORIO — del signal de estado
  subscriberId: string;         // ID del suscriptor (catálogo core-ohs)
  agentId: string;              // ID del agente (catálogo core-ohs)
  businessLineId: string;       // ID del giro (catálogo core-ohs)
  insuredName: string;
  insuredRfc?: string;
  policyStartDate: string;      // ISO-8601 date
  policyEndDate: string;        // ISO-8601 date
  factorComercial: number;      // Factor multiplicador de prima (ej: 1.15)
}
```

**Response** (`ApiResponse<GeneralInfoResponse>`):
```typescript
export interface GeneralInfoResponse {
  numeroFolio: string;
  estadoCotizacion: 'BORRADOR' | 'EN_PROCESO' | 'CALCULADA';
  version: number;              // NUEVA versión — actualizar el signal de estado
  subscriberId: string;
  agentId: string;
  businessLineId: string;
  insuredName: string;
  insuredRfc?: string;
  policyStartDate: string;
  policyEndDate: string;
  factorComercial: number;
}
```

**Regla de versionado**: Siempre enviar la `version` del signal. Si el backend retorna `409`, mostrar toast y NO reintentar.

---

### 6.3 `POST /v1/quotes/{folio}/calculate` — Ejecutar Motor de Cálculo

**Servicio**: `cotizacion.service.ts`

**Path param**: `folio: string`

**Request body**: vacío `{}` o sin body.

**Response** (`ApiResponse<CalculationResult>`):
```typescript
export interface CalculationResult {
  numeroFolio: string;
  estadoCotizacion: 'CALCULADA';
  version: number;
  primaNeta: number;            // Total neta de todas las ubicaciones válidas
  primaComercial: number;       // primaNeta × factorComercial
  primasPorUbicacion: UbicacionPrima[];
}

export interface UbicacionPrima {
  indice: number;
  descripcion: string;
  calculable: boolean;
  primaNeta?: number;
  primaComercial?: number;
  alertasBloqueantes: string[];
}
```

**Fórmula del motor de cálculo**:

| Concepto | Fórmula |
|----------|---------|
| Prima Neta por Ubicación | `Σ(conceptos 1–6)` donde cada concepto = `valorAsegurado × tarifa` |
| Concepto 6 (Ext. Catastrófica) | Solo aplica a `Edificio`, no a `Contenidos` |
| Prima Comercial por Ubicación | `primaNeta_ubicacion × factorComercial` |
| Prima Neta Total | `Σ primaNeta_ubicacion` (solo ubicaciones `calculable: true`) |
| Prima Comercial Total | `Σ primaComercial_ubicacion` (solo ubicaciones `calculable: true`) |

**Nota IVA**: El IVA está **fuera del alcance** del motor. No calcularlo ni mostrarlo.

---

### 6.4 `GET /v1/folios` (core-ohs) — Siguiente Número de Folio

**Servicio**: `core-ohs.service.ts`

**Response** (`ApiResponse<NextFolioResponse>`):
```typescript
export interface NextFolioResponse {
  numeroFolio: string;         // Ej: "DAN-2026-0001"
}
```

**Uso**: Llamar al inicializar `/cotizador` para obtener el `numeroFolio` antes de hacer `POST /v1/folios`.

---

### 6.5 `GET /v1/subscribers` — Catálogo de Suscriptores

**Servicio**: `core-ohs.service.ts`

```typescript
export interface Subscriber {
  id: string;
  name: string;
  rfc?: string;
}
```

---

### 6.6 `GET /v1/agents` — Catálogo de Agentes

**Servicio**: `core-ohs.service.ts`

```typescript
export interface Agent {
  id: string;
  name: string;
  clave?: string;
}
```

---

### 6.7 `GET /v1/business-lines` — Giros Comerciales

**Servicio**: `core-ohs.service.ts`

```typescript
export interface BusinessLine {
  id: string;
  name: string;
  claveIncendio: string;        // Campo crítico para el motor de cálculo
  riskClassification?: string;
}
```

---

### 6.8 `GET /v1/zip-codes/{zipCode}` — Información de Código Postal

**Servicio**: `core-ohs.service.ts`

**Path param**: `zipCode: string`

```typescript
export interface ZipCodeInfo {
  zipCode: string;
  estado: string;
  municipio: string;
  ciudad: string;
  colonia: string;
  zonaCatastrofica: string;     // Zona de riesgo catastrófico (A, B, C, D)
}
```

**Error 404**: Significa CP inválido → mostrar error inline bajo el campo `codigoPostal`.

---

### 6.9 `POST /v1/zip-codes/validate` — Validar Código Postal

**Servicio**: `core-ohs.service.ts`

**Request body**:
```typescript
export interface ZipCodeValidateRequest {
  zipCode: string;
}
```

**Response**:
```typescript
export interface ZipCodeValidateResponse {
  valid: boolean;
  zipCode: string;
}
```

---

### 6.10 `GET /v1/catalogs/risk-classification` — Clasificación de Riesgo

**Servicio**: `core-ohs.service.ts`

```typescript
export interface RiskClassification {
  id: string;
  name: string;
  description?: string;
}
```

---

### 6.11 `GET /v1/catalogs/guarantees` — Catálogo de Garantías

**Servicio**: `core-ohs.service.ts`

```typescript
export interface Guarantee {
  id: string;
  name: string;
  tarifable: boolean;
  aplicaContenidos: boolean;    // false = solo aplica a Edificio (ej: Concepto 6)
}
```

---

### 6.12 Tarifas — `GET /v1/tariffs/*` (core-ohs)

**Servicio**: `core-ohs.service.ts`

Los cuatro endpoints de tarifas devuelven estructuras similares:

| Endpoint | Descripción |
|----------|-------------|
| `GET /v1/tariffs/incendio` | Tarifa base de incendio por `claveIncendio` |
| `GET /v1/tariffs/cat` | Tarifa catastrófica por `zonaCatastrofica` |
| `GET /v1/tariffs/fhm` | Tarifa de fenómenos hidrometeorológicos |
| `GET /v1/tariffs/parametros-calculo` | Parámetros globales del motor (factores, límites) |

```typescript
export interface TariffEntry {
  clave: string;
  tasa: number;              // Tasa como decimal (ej: 0.0025 = 0.25%)
  descripcion?: string;
}

export interface CalculationParameters {
  factorMinimo: number;
  factorMaximo: number;
  tasaMinima: number;
  [key: string]: number;    // Otros parámetros del motor
}
```

---

## 7. Interfaces TypeScript — Modelo de Estado (Signals)

```typescript
// shared/models/cotizacion.model.ts
export type EstadoCotizacion = 'BORRADOR' | 'EN_PROCESO' | 'CALCULADA';

export interface Cotizacion {
  numeroFolio: string;
  estadoCotizacion: EstadoCotizacion;
  version: number;
  primaNeta?: number;
  primaComercial?: number;
  factorComercial?: number;
  primasPorUbicacion?: UbicacionPrima[];
}
```

---

## 8. Criterios de Aceptación para Servicios

### `cotizacion.service.ts`

- [ ] `createFolio(req: CreateFolioRequest): Observable<ApiResponse<FolioResponse>>`
- [ ] `updateGeneralInfo(folio: string, req: GeneralInfoRequest): Observable<ApiResponse<GeneralInfoResponse>>`
- [ ] `calculate(folio: string): Observable<ApiResponse<CalculationResult>>`
- [ ] URL base tomada de `environment.danosBackUrl` — nunca hardcodeada
- [ ] Llamadas tipadas con genérico: `http.post<ApiResponse<FolioResponse>>(...)`

### `core-ohs.service.ts`

- [ ] `getNextFolio(): Observable<ApiResponse<NextFolioResponse>>`
- [ ] `getSubscribers(): Observable<ApiResponse<Subscriber[]>>`
- [ ] `getAgents(): Observable<ApiResponse<Agent[]>>`
- [ ] `getBusinessLines(): Observable<ApiResponse<BusinessLine[]>>`
- [ ] `getRiskClassification(): Observable<ApiResponse<RiskClassification[]>>`
- [ ] `getGuarantees(): Observable<ApiResponse<Guarantee[]>>`
- [ ] `getZipCodeInfo(zipCode: string): Observable<ApiResponse<ZipCodeInfo>>`
- [ ] `validateZipCode(req: ZipCodeValidateRequest): Observable<ApiResponse<ZipCodeValidateResponse>>`
- [ ] `getTariffIncendio(): Observable<ApiResponse<TariffEntry[]>>`
- [ ] `getTariffCat(): Observable<ApiResponse<TariffEntry[]>>`
- [ ] `getTariffFhm(): Observable<ApiResponse<TariffEntry[]>>`
- [ ] `getCalculationParameters(): Observable<ApiResponse<CalculationParameters>>`
- [ ] URL base tomada de `environment.coreOhsUrl` — nunca hardcodeada

---

## 9. Criterios de Aceptación para Tests

### `cotizacion.service.spec.ts`

- [ ] **Happy path `createFolio`**: Mock HTTP retorna `201`. Verificar que se llama `POST /v1/folios` con el body correcto.
- [ ] **Idempotencia `createFolio`**: Mock HTTP retorna `200`. Verificar que se retorna el folio existente sin error.
- [ ] **Happy path `updateGeneralInfo`**: Verificar body incluye `version`. Verificar `PUT` a la URL correcta.
- [ ] **409 `updateGeneralInfo`**: Mock retorna `409 ProblemDetail`. Verificar que el Observable lanza error (el interceptor lo captura).
- [ ] **Happy path `calculate`**: Mock retorna `CalculationResult` con `estadoCotizacion: 'CALCULADA'`.
- [ ] **URLs**: Verificar que cada llamada usa `environment.danosBackUrl` como prefijo, no URL hardcodeada.

### `core-ohs.service.spec.ts`

- [ ] **Happy path `getZipCodeInfo`**: Mock retorna `ZipCodeInfo`. Verificar path param correcto.
- [ ] **404 `getZipCodeInfo`**: Mock retorna `404`. Verificar que Observable lanza error con `status: 404`.
- [ ] **Happy path `validateZipCode`**: Mock retorna `{ valid: true }`. Verificar body del POST.
- [ ] **Happy path catálogos** (subscribers, agents, business-lines): Un test por método. Verificar método GET y URL.
- [ ] **Tarifas**: Al menos un test por endpoint de tarifa verificando la URL correcta.
- [ ] **URLs**: Verificar que cada llamada usa `environment.coreOhsUrl` como prefijo.

### Estado de Signal — Integración con Servicio

- [ ] Cuando `createFolio` retorna OK → `loading()` pasa a `false` y `cotizacion()` se actualiza.
- [ ] Cuando `calculate` retorna OK → `cotizacion().estadoCotizacion === 'CALCULADA'` y `primaNeta` visible.
- [ ] Cuando `updateGeneralInfo` retorna OK → `version` del signal se actualiza con la nueva `version` del response.
