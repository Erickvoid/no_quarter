# No Quarter — Refugio v1.3

Sistema de control financiero personal 100% local para Android.

## Qué hace la app

Refugio organiza el dinero por periodos con una regla principal:
- proteger las Necesidades del Hogar,
- separar automáticamente el dinero por porcentajes,
- liquidar deudas con estrategia,
- controlar gastos fijos mensuales con fecha,
- y mantener visibilidad del resultado mensual e historial.

## Stack técnico

- Flutter / Dart
- Hive + Hive Flutter (persistencia local)
- google_generative_ai (Gemini)
- intl (moneda/fechas)
- uuid

## Regla financiera central (v1.3)

Cada ingreso se divide automáticamente con la configuración activa del usuario:

1) Necesidades del Hogar (`% configurable`, default 50%)
- Partidas editables (nombre y monto)
- Base para checklist semanal

2) Gastos Personales (`% configurable`, default 30%)
- Uso discrecional

3) Ahorro y Deudas (`% automático`, default 20%)
- Pago de deudas
- Ahorro / inversión

Además, la frecuencia del periodo ahora es configurable:
- Semanal
- Quincenal
- Mensual

## Módulos principales

### 1) Inicio (`lib/screens/centro_de_mando_screen.dart`)
- Saldo total por banco configurado
- Estado de Necesidades del Hogar + checklist semanal
- Dinero Disponible
- Distribucion del ingreso (Necesidades/Gastos/Ahorro-Deudas)
- Preview de gastos fijos mensuales (fecha, monto, estado)
- Resumen de deudas por categoria

### 2) Ingresos (`lib/screens/suministros_screen.dart`)
- Registro de ingresos (nómina / extra)
- Separacion automatica por porcentajes configurables

### 3) Deudas (`lib/screens/frentes_de_batalla_screen.dart`)
- Alta y gestion de deudas por categoria
- Registro de pagos
- División de adeudo en pagos semanales (monto + día límite)
- Alta rapida de gasto fijo mensual
- Creacion de metas de ahorro desde la misma pantalla

### 4) Asesor IA (`lib/screens/asistente_tactico_screen.dart`)
- Consulta financiera con Gemini
- Veredicto: `VIABLE`, `REQUIERE AJUSTE`, `NO RECOMENDADO`
- Diagnóstico ejecutivo
- Contexto ampliado con:
  - deudas,
  - fondos de ahorro/inversión,
  - gastos fijos,
  - pendientes,
  - resultado mensual,
  - banco/frecuencia/porcentajes configurados.

### 5) Fondos (`lib/screens/fondos_screen.dart`)
- Fondos de ahorro e inversión
- Depósitos/retiros
- Historial de movimientos
- Flujo alineado a saldo disponible real para ahorrar

### 6) Info (`lib/screens/info_screen.dart`)
- Pendientes semanales + gastos fijos pendientes
- Administración de gastos fijos por fecha (día del mes)
- Balance mensual (ingresos, salidas, neto de caja)
- Historial por mes (expansible)

### 7) Configuración (`lib/screens/settings_screen.dart`)
- Nombre de banco principal
- Porcentajes de distribucion de ingreso
- Frecuencia financiera (semanal/quincenal/mensual)
- Plantillas de partidas para Necesidades del Hogar
- Restablecer valores por defecto

## Diferencia clave: Deudas vs Gastos fijos

- **Deudas:** compromisos con saldo restante y liquidacion.
- **Gastos fijos mensuales:** servicios/recurrencias con fecha de vencimiento mensual.

No son lo mismo y se guardan por separado.

## Persistencia (Hive)

La base de datos vive en el almacenamiento interno de Android:
- `/data/data/com.noquarter.paid_calm/app_flutter/`

Boxes principales:
- `incomes`
- `debts`
- `payments`
- `fondo_items`
- `savings_funds`
- `savings_movements`
- `fixed_expenses`
- `fixed_expense_payments`
- `settings`

## Modelos Hive

- `Income` (typeId 0)
- `DebtCategory` (typeId 1)
- `Debt` (typeId 2)
- `DebtPayment` (typeId 3)
- `FondoItem` (typeId 4)
- `SavingsFund` (typeId 5)
- `SavingsMovement` (typeId 6)
- `FixedExpense` (typeId 7)
- `FixedExpensePayment` (typeId 8)

## Flujo de cálculo relevante

En `lib/services/database_service.dart`:
- `getSaldoTotal()`
- `getNecesidadesAsignadas()`
- `isNecesidadesCubiertas()`
- `getGastosDisponibles()`
- `getAhorroDisponible()`
- `getTotalDisponible()`
- `getCurrentPeriodStart()`
- `getNeedsPercent()`
- `getWantsPercent()`
- `getSavingsPercent()`
- `getFrequencyLabel()`
- `splitDebtIntoWeeklyPlan(...)`
- `getPendingInfoItems()`
- `getCurrentMonthSummary()`
- `getMonthSummaryByDate(...)`
- `getMonthsWithData()`

## Estado actual

- Configuracion financiera completa habilitada desde UI.
- Distribucion de ingresos por porcentajes en lugar de monto fijo.
- Necesidades del Hogar con partidas editables (agregar/editar/eliminar).
- Resumen mensual y historial de meses anteriores.
- Ajustes de lenguaje en toda la app (Inicio, Deudas, Historial, Disponible).
- Gemini actualizado para contexto familiar y reglas de Necesidades del Hogar.
- Corregido overflow horizontal en Configuracion para pantallas angostas.
