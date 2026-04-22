# Copilot Instructions — Gestión Financiera de Manufactura (Flutter + Firebase)

Este repositorio contiene **únicamente** la app Flutter de gestión financiera para un negocio interno familiar de manufactura.
La app usa Firebase Auth y Cloud Firestore como infraestructura de datos.

---

## Agentes Disponibles

| Agente | Fase | Archivo |
|--------|------|---------|
| Orchestrator | Coordinación | `.github/agents/orchestrator.agent.md` |
| Spec Generator | 1. Spec | `.github/agents/spec-generator.agent.md` |
| Flutter Developer | 2. Implementación | `.github/agents/frontend-developer.agent.md` |
| Test Engineer Flutter | 3. Tests unitarios | `.github/agents/test-engineer-frontend.agent.md` |
| QA Agent | 4. QA UI | `.github/agents/qa.agent.md` |
| Documentation Agent | 5. Docs | `.github/agents/documentation.agent.md` |

---

## Flujo de Desarrollo (ASDD Flutter)

```
[Orchestrator] → [Spec Generator] → [Flutter Developer] → [Test Engineer Flutter] → [QA] → [Doc]
```

1. **Spec**: `spec-generator` crea `.github/specs/<feature>.spec.md` (debe alcanzar `status: APPROVED`).
2. **Implementación**: `flutter-developer` crea models → repositories → state → widgets → routes.
3. **Tests**: `test-engineer-flutter` genera tests unitarios y de widgets para estado, repositorios y UI.
4. **QA**: `qa-agent` genera escenarios Gherkin enfocados en UI, accesibilidad y flujos de pantalla.
5. **Docs**: `documentation-agent` actualiza README, arquitectura visual y guías de widgets.

---

## Reglas de Oro

1. **Flutter primero**: no generar artefactos de otro stack frontend.
2. **Estado con Riverpod**: usar providers y notifiers; no usar `BehaviorSubject`.
3. **Firebase Auth y Firestore**: la app persiste en Firebase; no hay backend propio.
4. **Routing con go_router**: navegación declarativa por feature.
5. **Specs obligatorias**: ninguna feature se implementa sin spec aprobada.
6. **Diseño consistente**: seguir `ui-design.spec.md` y priorizar usabilidad para una usuaria no técnica.
7. **No secretos**: nada de credenciales en código, texto plano ni documentación pública.

---

## Fuentes De Verdad

- `ARCHITECTURE.md`
- `DATA_MODEL.md`
- `.github/specs/firebase-contracts.spec.md`
- `.github/specs/ui-design.spec.md`
- `.github/specs/frontend-feature.spec.template.md`
- `.github/instructions/frontend.instructions.md`

---

## Definition of Ready (Spec)

Una spec está lista para implementar cuando:
- `status: APPROVED` en el frontmatter
- Tiene definidos: pantallas, colecciones Firestore, estado requerido, comportamiento UI y validaciones

## Definition of Done (Implementación)

Un feature está "hecho" cuando:
- Pantallas y widgets creados con Flutter y rutas registradas en `go_router`
- State con providers/notifiers y manejo explícito de `loading`/`error`
- Repositorios que encapsulan Firebase Auth / Firestore
- UI alineada con `ui-design.spec.md`
- Sin `print()` ni trazas de depuración en producción

---

## Diccionario de Dominio

| Término | Definición |
|---------|-----------|
| **Materia prima** | Insumo base con precio actual y unidad definida |
| **Categoría de materia prima** | Clasificación de materias primas; `lona` tiene una regla especial |
| **Subproducto** | Composición intermedia construida solo desde materias primas |
| **Producto final** | Ensamble de uno o varios subproductos |
| **Simulador** | Cálculo de costo y materiales para X unidades |
| **clientePoneLaLona** | Flag que excluye materias primas de categoría `lona` del cálculo |

**Nomenclatura**: `camelCase` en Dart · `snake_case` en nombres de archivos · clases en `PascalCase`.
