# AGENTS.md — mi_app (Flutter + Firebase)

> Reglas activas para todos los agentes que trabajen en este repositorio.

Este repositorio contiene **solo** la app Flutter de gestión financiera para manufactura, conectada a Firebase Auth y Cloud Firestore.
No contiene backend propio, ni Java, ni Spring Boot.

---

## Agentes Activos

| Agente | Archivo | Fase |
|--------|---------|------|
| **Orchestrator** | `.github/agents/orchestrator.agent.md` | Coordinación |
| **Spec Generator** | `.github/agents/spec-generator.agent.md` | Especificación (Fase 1) |
| **Flutter Developer** | `.github/agents/frontend-developer.agent.md` | Implementación (Fase 2) |
| **Test Engineer Flutter** | `.github/agents/test-engineer-frontend.agent.md` | Tests unitarios (Fase 3) |
| **QA Agent** | `.github/agents/qa.agent.md` | Gherkin y UI Risks (Fase 4) |
| **Documentation Agent** | `.github/agents/documentation.agent.md` | Documentación (Fase 5) |

---

## Flujo de Trabajo (ASDD Flutter)

```
[Orchestrator]
      ↓
[1. Spec] → [2. Flutter Developer] → [3. Test Engineer Flutter] → [4. QA Agent] → [5. Doc Agent]
```

1. **Spec Generator**: Genera `.github/specs/<feature>.spec.md`. Debe tener `status: APPROVED` antes de seguir.
2. **Flutter Developer**: Implementa `models` → `repositories` → `state` → `widgets` → `routes`.
3. **Test Engineer Flutter**: Genera tests unitarios y de widgets para lógica, estado y Firebase.
4. **QA Agent**: Genera escenarios Gherkin enfocados en UI/UX, accesibilidad y casos borde.
5. **Documentation Agent**: Actualiza README, guías y documentación visual.

---

## Fuentes de Verdad

> Los agentes deben leer estos documentos antes de generar specs, implementar o testear.

| Documento | Propósito |
|-----------|-----------|
| `ARCHITECTURE.md` | Arquitectura funcional y técnica del proyecto |
| `DATA_MODEL.md` | Modelo de datos y reglas de cálculo |
| `.github/specs/firebase-contracts.spec.md` | Fuente de verdad de Firebase Auth, Firestore y permisos |
| `.github/specs/ui-design.spec.md` | Sistema de diseño y UX |
| `.github/specs/frontend-feature.spec.template.md` | Plantilla base para cada spec funcional |
| `.github/instructions/frontend.instructions.md` | Stack, estructura y restricciones Flutter |

---

## Reglas de Oro

### I. Integridad del Código

- **No código no autorizado**: no generar código sin solicitud explícita del usuario.
- **No modificaciones no autorizadas**: no modificar archivos sin aprobación explícita.
- **Preservar la lógica existente**: respetar patrones arquitectónicos y estilo del proyecto.
- **No mezclar stacks**: no introducir artefactos de otro stack frontend ni conceptos de backend Java.

### II. Reglas Técnicas No Negociables

1. **Flutter nativo**: usar widgets, rutas y proveedores de estado de Flutter; evitar mezclas con stacks anteriores.
2. **Estado con Riverpod**: preferir `Notifier` / `AsyncNotifier` / providers inyectables; no usar `BehaviorSubject` ni patrones de UI de otros frameworks.
3. **Navegación con go_router**: rutas por feature, navegación declarativa y profunda.
4. **Firebase como backend**: Firebase Auth y Firestore son la fuente de autenticación y persistencia.
5. **Config segura**: no hardcodear credenciales; usar `flutterfire configure` y archivos generados.
6. **Specs obligatorias**: ninguna implementación sin spec aprobada.
7. **No secretos**: ninguna API key, token o credencial en el código fuente.

### III. Clarificación de Requisitos

- Si la solicitud es ambigua o incompleta, detenerse y pedir clarificación antes de proceder.
- No realizar suposiciones; basar todas las acciones en información explícita del usuario.

---

## Comandos de Desarrollo

```bash
flutter pub get
flutter run
flutter test
flutter build apk
```
