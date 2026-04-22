# Frontend — Cotizador de Daños (Angular 19)

Este repositorio contiene **exclusivamente** el frontend (`cotizador-danos-web`), una SPA Angular 19 que no incluye código de backend, base de datos ni Docker.

---

## Backends de Referencia

| Servicio | URL base | Descripción |
|----------|----------|-------------|
| `plataforma-danos-back` | `http://localhost:8080` | Lógica de negocio de cotización |
| `plataforma-core-ohs` | `http://localhost:8081` | Stub de servicios core (códigos postales, tarifas) |

> Las URLs se configuran en `src/environments/environment.ts`. **Nunca hardcodear** URLs en el código.

---

## Flujo de Desarrollo (ASDD Frontend)

```
Requerimiento → Spec → Frontend Developer → Test Engineer FE → QA
```

### Paso 1 — Spec
```
/generate-spec <nombre-feature>
```
Genera `.github/specs/<feature>.spec.md`. Debe alcanzar `status: APPROVED` antes de implementar.

### Paso 2 — Implementación
```
/implement-frontend <nombre-feature>
```
Orden: Models → State (Signals) → HTTP Service → Component → Template (Tailwind).

### Paso 3 — Tests
```
/unit-testing <nombre-feature>
```
Tests de state service, HTTP service y componente con Jasmine/Jest.

---

## Comandos de Desarrollo

```bash
npm install          # Instalar dependencias
ng serve             # Dev server → http://localhost:4200
ng build --configuration production
ng test              # Tests unitarios
```

---

> Ver `ARCHITECTURE.md` en la raíz del proyecto para arquitectura completa, contratos de API y reglas de UI.
