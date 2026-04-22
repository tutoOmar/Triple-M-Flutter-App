---
applyTo: "lib/**/*.dart,test/**/*.dart"
---

> **Scope**: Se aplica a todo el código Flutter en `lib/` y `test/`.

# Instrucciones para Frontend (Flutter + Firebase)

## Stack Fijo (No Negociable)

- **Flutter** para la interfaz completa
- **Dart** con null safety habilitado
- **Riverpod** para estado de aplicación y dependencias
- **go_router** para navegación declarativa y lazy feature loading
- **Firebase Auth** para login con correo/contraseña
- **Cloud Firestore** como persistencia principal
- **Material 3** con tema propio y paleta corporativa
- **Sin librerías de UI de terceros** salvo aprobación explícita

## Estructura de Archivos

```
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
├── core/
│   ├── config/
│   │   └── firebase_options.dart
│   ├── firestore/
│   ├── auth/
│   ├── errors/
│   └── widgets/
├── shared/
│   ├── models/
│   └── utils/
└── features/
    ├── auth/
    ├── home/
    ├── materials/
    ├── categories/
    ├── subproducts/
    ├── products/
    └── simulator/
```

## Patrón de Estado con Riverpod

Cada feature debe exponer estado con providers o notifiers.
Preferir `AsyncNotifier` o `Notifier` para casos de carga y mutación.

```dart
class ProductsController extends AsyncNotifier<ProductsState> {
  @override
  Future<ProductsState> build() async {
    return const ProductsState.initial();
  }
}
```

Reglas:

- no exponer estado mutable fuera del provider;
- separar UI de lógica de cálculo;
- aislar llamadas a Firestore en repositorios;
- usar `FutureProvider` o `StreamProvider` solo para lecturas simples.

## Patrón de Navegación

Usar `go_router` con rutas declarativas por feature.

Ejemplo:

```dart
GoRoute(
  path: '/products/:id',
  builder: (context, state) => ProductDetailPage(productId: state.pathParameters['id']!),
)
```

## Firebase

- Inicializar con `flutterfire configure`.
- Consumir `firebase_options.dart` generado.
- No hardcodear project IDs, api keys ni nombres de ambiente en la UI.
- Encapsular acceso a Auth y Firestore en repositorios o servicios de infraestructura.

## UI y Sistema de Diseño

- La interfaz sigue `ui-design.spec.md`.
- Prioridad: claridad, lectura rápida y taps simples para una usuaria no técnica.
- Mobile first, luego tablet y PC.
- Mantener jerarquía visual fuerte con tarjetas, listados compactos y acciones primarias claras.
- El color primario es `#0C447C`.
- Preferir `TextFormField`, `DropdownButtonFormField`, `Card`, `ListTile`, `Dialog`, `BottomSheet`, `NavigationBar` y `Drawer` solo cuando aporte valor.
- Mantener espacios moderados; no saturar la interfaz con demasiada densidad.

## Reglas de Formulario

- Validar en el cliente antes de escribir a Firestore.
- Mensajes cortos, específicos y visibles junto al campo.
- No bloquear toda la pantalla por errores de validación de un campo.
- En acciones destructivas, pedir confirmación explícita.

## Repositorios y Datos

- Los repositorios deben traducir Firestore a modelos de dominio.
- Usar mapeo explícito `fromMap` / `toMap`.
- No mezclar query builders con widgets.
- Mantener operaciones de lectura y escritura pequeñas y predecibles.

## Manejo de Errores

- Capturar `FirebaseAuthException` y `FirebaseException` donde corresponda.
- Mostrar mensajes de negocio legibles para el usuario.
- Los errores técnicos no deben exponerse completos en la UI.
- Registrar logs de depuración solo en desarrollo.

## Convenciones de Código

- Archivos en `snake_case.dart`.
- Clases, widgets y notifiers en `PascalCase`.
- Métodos y variables en `camelCase`.
- Mantener nombres de dominio consistentes con `ARCHITECTURE.md` y `DATA_MODEL.md`.
- Evitar funciones demasiado largas; extraer helpers cuando la intención no sea clara.

## Restricciones

- NO usar artefactos de otro stack frontend ni templates HTML ajenos a Flutter.
- NO instalar o introducir componentes UI de terceros sin aprobación.
- NO crear backend propio ni servicios REST nuevos salvo que una spec lo pida explícitamente.
- NO usar `print()` para depuración en producción.
- NO hardcodear secretos ni llaves Firebase.

> Ver `ARCHITECTURE.md` y `DATA_MODEL.md` en la raíz del repositorio para la arquitectura completa y las reglas de negocio.
