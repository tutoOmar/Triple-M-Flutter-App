# 📋 Lineamientos de Desarrollo
# Versión: 2.0.0
# Última actualización: 2026-04-21

## 1. Estándares de Código

### Nomenclatura
- Clases, widgets y notifiers: PascalCase.
- Métodos y variables: camelCase.
- Constantes: UPPER_SNAKE_CASE cuando sean globales.
- Archivos: snake_case.dart.

### Estructura de Carpetas
```
lib/
├── app/
├── core/
├── shared/
└── features/
test/
```

### Reglas de Código
- Mantener widgets pequeños y con una sola responsabilidad.
- Extraer lógica de negocio fuera de la UI.
- Sin números mágicos; usar constantes o valores de configuración.
- Sin comentarios que expliquen lo obvio.
- Manejo explícito de errores en cada flujo que toque Firebase.

## 2. Estándares de Testing

### Cobertura Mínima Requerida
- Unitarios: 80% mínimo en lógica de negocio.
- Provider tests: todos los notifiers y estados críticos cubiertos.
- Widget tests: flujos de pantalla críticos cubiertos.

### Nomenclatura de Tests
```
given_[context]_when_[action]_then_[expected]
```

### Estructura de Tests (AAA)
- Arrange: preparar datos de prueba.
- Act: ejecutar la acción bajo prueba.
- Assert: verificar el resultado esperado.

## 3. Estándares de Datos

### Convenciones Firestore
- Colecciones y campos alineados a `DATA_MODEL.md`.
- IDs legibles cuando sea posible.
- Fechas como `Timestamp`.
- No persistir valores derivados si ya se pueden calcular.

### Respuesta de operaciones internas
- Los repositorios deben devolver modelos tipados o errores claros.
- No exponer excepciones crudas en la UI.

## 4. Estándares de Git

### Ramas
- `main` → producción.
- `develop` → integración.
- `feature/[ticket]-descripcion` → nuevas funcionalidades.
- `bugfix/[ticket]-descripcion` → corrección de bugs.

### Commits (Conventional Commits)
```
feat: agrega simulador de producción
fix: corrige validación de receta
test: agrega tests para provider de materiales
docs: actualiza guía de widgets
refactor: extrae mapper de Firestore
chore: actualiza dependencias de Firebase
```

## 5. Estándares de Seguridad

- No hardcodear secretos ni llaves Firebase.
- Validar los inputs antes de escribir en Firestore.
- No registrar PII, contraseñas ni datos financieros completos.
- Restringir acceso a datos con Firebase Auth y reglas de Firestore.
- Mantener configuraciones de Firebase fuera del código fuente manual.

## 6. Estándares de Pipeline

### Quality Gates Obligatorios
- `flutter analyze` sin errores.
- `flutter test` exitoso.
- Cobertura suficiente en la lógica crítica.
- Sin secretos expuestos.

### Stages del Pipeline en Orden
1. `analyze` → análisis estático.
2. `test` → unitarios y widgets.
3. `build` → compilación.
4. `security-scan` → dependencias y secretos.

### Ambientes
- `develop` → validación interna.
- `main` → release estable.
