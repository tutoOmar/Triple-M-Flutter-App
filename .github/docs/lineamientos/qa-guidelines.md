
# Guía de Lineamientos y Mejores Prácticas: QA Flutter

Este documento resume buenas prácticas para QA de la app Flutter de manufactura, con foco en UX, validaciones y regresión funcional.

## 1. Enfoque de trabajo

- Priorizar features críticas: login, catálogos, simulador y cálculo.
- Acompañar el flujo ASDD con casos claros y rastreables.
- Mantener la conversación enfocada en riesgo real de usuario.

## 2. Diseño de escenarios

- Escribir Gherkin para flujos principales, alternos y de borde.
- Cubrir estados vacío, loading y error.
- Incluir validaciones inline y comportamiento responsive.
- Verificar explícitamente la variante `clientProvidesLona`.

## 3. Ejecución y evidencia

- Documentar la evidencia por escenario.
- Registrar defectos con pasos claros y contexto suficiente.
- Confirmar los re-tests antes de cerrar un bug.

## 4. Automatización

- Priorizar tests de widget e integración sobre E2E pesados.
- Mantener datos desacoplados y deterministas.
- Evitar flakiness, sleeps y dependencia de datos externos.

## 5. Riesgos a vigilar

- Errores de Firebase Auth.
- Lecturas vacías o permisos insuficientes en Firestore.
- Cálculos incorrectos por recetas incompletas.
- Problemas de responsive en móvil y escritorio.

## 6. Comunicación

- Mantener trazabilidad entre spec, implementación y QA.
- Informar de riesgos o ambigüedades antes de validar.
