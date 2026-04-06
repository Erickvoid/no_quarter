# No Quarter — Refugio v1.2

Sistema de control financiero personal 100% local para Android.

## Qué hace la app

Refugio organiza el dinero semanal con una regla principal:
- proteger el Fondo Intocable,
- operar con Capital Libre,
- liquidar pasivos con estrategia,
- controlar gastos fijos mensuales con fecha,
- y mantener visibilidad del resultado mensual.

## Stack técnico

- Flutter / Dart
- Hive + Hive Flutter (persistencia local)
- google_generative_ai (Gemini)
- intl (moneda/fechas)
- uuid

## Regla financiera central

Cada ingreso semanal se separa en:

1) Fondo Intocable (`$2,810 MXN`)
- Gasolina
- Despensa
- Apoyo a mamá
- Mascotas

2) Capital Libre (`ingreso - 2810`)
- Pagos a pasivos
- Gastos discrecionales
- Ahorro / inversión
- Gastos fijos mensuales

## Módulos principales

### 1) Panel de Control (`lib/screens/centro_de_mando_screen.dart`)
- Saldo total
- Estado del Fondo Intocable + checklist semanal
- Capital Libre
- Preview de gastos fijos mensuales (fecha, monto, estado)
- Resumen de pasivos por categoría

### 2) Ingresos (`lib/screens/suministros_screen.dart`)
- Registro de ingresos (nómina / extra)
- Separación automática en Fondo Intocable y Capital Libre

### 3) Pasivos (`lib/screens/frentes_de_batalla_screen.dart`)
- Alta y gestión de pasivos por categoría
- Registro de pagos
- División de adeudo en pagos semanales (monto + día límite)
- Alta rápida de gasto fijo mensual

### 4) Asesor IA (`lib/screens/asistente_tactico_screen.dart`)
- Consulta financiera con Gemini
- Veredicto: `VIABLE`, `REQUIERE AJUSTE`, `NO RECOMENDADO`
- Diagnóstico ejecutivo
- Contexto ampliado con:
  - pasivos,
  - fondos de ahorro/inversión,
  - gastos fijos,
  - pendientes,
  - resultado mensual.

### 5) Fondos (`lib/screens/fondos_screen.dart`)
- Fondos de ahorro e inversión
- Depósitos/retiros
- Historial de movimientos

### 6) Info (`lib/screens/info_screen.dart`)
- Pendientes semanales + gastos fijos pendientes
- Administración de gastos fijos por fecha (día del mes)
- Balance mensual (ingresos, salidas, neto de caja)

## Diferencia clave: Pasivos vs Gastos fijos

- **Pasivos (deudas):** compromisos con saldo restante y liquidación.
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
- `getBloqueDeTitanioThisWeek()`
- `getMunicionLibreTotal()`
- `splitDebtIntoWeeklyPlan(...)`
- `getPendingInfoItems()`
- `getCurrentMonthSummary()`

## Estado actual

- Gastos fijos mensuales integrados y visibles con fecha.
- Planes semanales por adeudo activos.
- Sección de pendientes y balance mensual funcional.
- Gemini actualizado para leer el contexto nuevo completo.
