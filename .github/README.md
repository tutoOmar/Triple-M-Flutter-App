# Flutter + Firebase

Este repositorio contiene la app Flutter de gestión financiera para un negocio interno de manufactura.
La app usa Firebase Auth y Cloud Firestore como base técnica.

---

## Flujo de Desarrollo (ASDD Flutter)

```
Requerimiento → Spec → Flutter Developer → Test Engineer Flutter → QA → Doc
```

### Paso 1 — Spec

Genera `.github/specs/<feature>.spec.md`. Debe alcanzar `status: APPROVED` antes de implementar.

### Paso 2 — Implementación

Orden: Models → Repositories → State/Providers → Widgets → Routes → Theme.

### Paso 3 — Tests

Tests de providers, repositorios y widgets con `flutter_test`.

---

## Comandos de Desarrollo

```bash
flutter pub get
flutter run
flutter test
flutter build apk
```

---

> Ver `ARCHITECTURE.md` y `DATA_MODEL.md` en la raíz del proyecto para arquitectura completa y reglas de negocio.
