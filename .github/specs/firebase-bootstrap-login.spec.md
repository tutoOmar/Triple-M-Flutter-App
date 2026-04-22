---
status: DRAFT
feature: firebase-bootstrap-login
author: spec-generator
created: 2026-04-22
scope: app bootstrap, Firebase Auth, Firestore, login and logout
---

# Spec: Firebase Bootstrap + Login

## 1. Objetivo

Configurar la app Flutter para conectarse a Firebase y permitir el acceso inicial con correo y contraseña.
Esta spec cubre el arranque base del proyecto y el acceso autenticado, que es requisito para usar cualquier otra parte de la app.
Tambien deja listo el proyecto para leer y escribir en Firestore desde el primer arranque.

## 2. Alcance

Incluye:

- configuración inicial de Firebase con `flutterfire configure`;
- inicialización de Firebase en la app;
- instalación de los paquetes base de Firebase para Flutter;
- login con correo y contraseña;
- logout;
- reglas base de acceso autenticado;
- pantalla inicial de entrada al sistema.

Excluye:

- recuperación de contraseña;
- registro público;
- Storage, Cloud Functions, mensajería y analítica;
- configuración de módulos funcionales de negocio.

## 3. Usuarios y permisos

- `admin`: acceso completo a la app.
- `operadora`: acceso a consulta y edición según las reglas de cada módulo funcional.

No existe acceso anónimo.

## 4. Dependencias de datos

- Firebase Auth.
- Firestore.
- `firebase_core`.
- `firebase_auth`.
- `cloud_firestore`.
- `.github/specs/firebase-contracts.spec.md`.
- `DATA_MODEL.md`.

## 5. UX esperado

- Pantalla simple de acceso con correo y contraseña.
- Mensajes de error breves y claros.
- Botón de entrar visible.
- Al autenticar, llevar al catálogo principal de productos.
- Si la sesión existe, entrar directamente sin repetir login.
- Si Firebase falla al inicializar, mostrar un estado de error comprensible y no una pantalla rota.

## 6. Estado requerido

- provider o notifier de autenticación;
- estado de sesión actual;
- loading de login;
- error de autenticación;
- usuario autenticado y rol.
- estado de inicialización de Firebase;
- estado de conexión inicial a Firestore cuando corresponda.

## 7. Reglas de negocio

- El login usa correo y contraseña.
- El logout cierra la sesión y limpia estado local.
- No existe registro público.
- Si el usuario no está autenticado, no puede entrar al resto de la app.
- La app debe fallar de forma controlada si Firebase no está inicializado.
- El arranque de la app debe esperar a `Firebase.initializeApp` antes de renderizar la navegación protegida.

## 8. Casos borde

- credenciales inválidas;
- sesión expirada;
- Firebase no inicializado;
- usuario deshabilitado;
- error de red al autenticar.

## 9. Criterios de aceptación

- La app inicializa Firebase antes de mostrar el contenido principal.
- La app usa la configuración generada por FlutterFire (`firebase_options.dart`).
- El usuario puede iniciar sesión con correo y contraseña.
- El usuario puede cerrar sesión.
- La app no permite navegar a módulos protegidos sin autenticación.
- Los errores de autenticación se muestran de forma legible.
- La app queda lista para usar Firestore desde la misma base de inicialización.

## 10. Notas de implementación

- Ejecutar primero:

	```bash
	dart pub global activate flutterfire_cli
	flutterfire configure --project=triple-m-1bda1
	```

- La inicialización en `main.dart` debe seguir esta secuencia:

	```dart
	import 'package:firebase_core/firebase_core.dart';
	import 'firebase_options.dart';

	Future<void> main() async {
		WidgetsFlutterBinding.ensureInitialized();
		await Firebase.initializeApp(
			options: DefaultFirebaseOptions.currentPlatform,
		);
		runApp(const MyApp());
	}
	```

- Deben existir las dependencias base de Firebase para Flutter antes de implementar el login.
- La navegación debe redirigir por estado de sesión.
- Esta spec es la base técnica para que las demás specs de negocio puedan leer y escribir en Firestore.

## 11. Estrategia de pruebas

- test de login exitoso;
- test de credenciales inválidas;
- test de logout;
- test de redirección por sesión activa;
- test de estado inicial sin Firebase listo.
