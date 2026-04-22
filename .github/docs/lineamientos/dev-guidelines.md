
# Resumen de Lineamientos de Desarrollo

Este documento centraliza principios prácticos para mantener la app Flutter limpia, mantenible y segura.

## 1. Seguridad por defecto

- No hardcodear secretos ni credenciales Firebase.
- Validar cualquier entrada antes de persistir.
- No registrar PII, contraseñas ni datos financieros completos.
- Mantener el acceso a datos restringido por Firebase Auth y reglas de Firestore.

## 2. Código limpio

- Widgets pequeños y con una sola responsabilidad.
- Lógica de negocio fuera de la UI.
- Nombres alineados al dominio.
- Sin código muerto ni valores mágicos sin constante.
- Preferir tipos explícitos en modelos y repositorios.

## 3. Diseño y mantenibilidad

- Separar `app`, `core`, `shared` y `features`.
- Inyectar dependencias para facilitar pruebas.
- Mantener mappers de Firestore explícitos.
- Evitar acoplar widgets con Firebase directo.

## 4. Testing

- Unit tests para cálculo y validación.
- Provider tests para estado y carga.
- Widget tests para pantallas críticas.
- Tests deterministas, sin depender de red real.

## 5. Observabilidad

- Logs estructurados solo en desarrollo o capa técnica.
- Errores técnicos traducidos a mensajes legibles.
- No mostrar stack traces al usuario.

## 6. Git y documentación

- Conventional Commits.
- Toda modificación relevante debe ir documentada.
- La documentación debe vivir junto al cambio en el mismo flujo ASDD.