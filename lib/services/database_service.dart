import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/income.dart';
import '../models/debt.dart';
import '../models/fondo_item.dart';
import '../models/savings_fund.dart';
import '../models/fixed_expense.dart';
import '../models/constants.dart';

class DatabaseService {
  // ── Hive box names (no cambiar — son las claves de almacenamiento real) ──
  static const String _incomeBox               = 'incomes';
  static const String _debtBox                 = 'debts';
  static const String _paymentBox              = 'payments';
  static const String _partidasBox             = 'fondo_items';
  static const String _savingsFundsBox         = 'savings_funds';
  static const String _savingsMovementsBox     = 'savings_movements';
  static const String _fixedExpensesBox        = 'fixed_expenses';
  static const String _fixedExpensePaymentsBox = 'fixed_expense_payments';
  static const String _settingsBox             = 'settings';

  static final _uuid = Uuid();

  // ── Initialization ──

  static Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(IncomeAdapter());
    Hive.registerAdapter(DebtCategoryAdapter());
    Hive.registerAdapter(DebtAdapter());
    Hive.registerAdapter(DebtPaymentAdapter());
    Hive.registerAdapter(FondoItemAdapter());
    Hive.registerAdapter(SavingsFundAdapter());
    Hive.registerAdapter(SavingsMovementAdapter());
    Hive.registerAdapter(FixedExpenseAdapter());
    Hive.registerAdapter(FixedExpensePaymentAdapter());

    await Hive.openBox<Income>(_incomeBox);
    await Hive.openBox<Debt>(_debtBox);
    await Hive.openBox<DebtPayment>(_paymentBox);
    await Hive.openBox<FondoItem>(_partidasBox);
    await Hive.openBox<SavingsFund>(_savingsFundsBox);
    await Hive.openBox<SavingsMovement>(_savingsMovementsBox);
    await Hive.openBox<FixedExpense>(_fixedExpensesBox);
    await Hive.openBox<FixedExpensePayment>(_fixedExpensePaymentsBox);
    await Hive.openBox(_settingsBox);
  }

  // ── Box accessors ──

  static Box<Income>              get _ingresos          => Hive.box<Income>(_incomeBox);
  static Box<Debt>                get _deudas            => Hive.box<Debt>(_debtBox);
  static Box<DebtPayment>         get _pagos             => Hive.box<DebtPayment>(_paymentBox);
  static Box<FondoItem>           get _partidas          => Hive.box<FondoItem>(_partidasBox);
  static Box<SavingsFund>         get _fondosAhorro      => Hive.box<SavingsFund>(_savingsFundsBox);
  static Box<SavingsMovement>     get _movimientosAhorro => Hive.box<SavingsMovement>(_savingsMovementsBox);
  static Box<FixedExpense>        get _gastosFijos       => Hive.box<FixedExpense>(_fixedExpensesBox);
  static Box<FixedExpensePayment> get _pagosFijos        => Hive.box<FixedExpensePayment>(_fixedExpensePaymentsBox);
  static Box                      get _config            => Hive.box(_settingsBox);

  static String generateId() => _uuid.v4();

  // ── Config keys ──

  static const String _bankNameKey         = 'cfg_bank_name';
  static const String _limiteNecesidadesKey = 'cfg_fondo_amount';  // clave legacy preservada
  static const String _needsPctKey         = 'cfg_needs_percent';
  static const String _wantsPctKey         = 'cfg_wants_percent';
  static const String _frequencyKey        = 'cfg_frequency';
  static const String _plantillasKey       = 'cfg_fondo_templates';

  // ── Configuración: banco ──

  static String getBankName() =>
      (_config.get(_bankNameKey, defaultValue: 'BBVA') as String?) ?? 'BBVA';
  static Future<void> setBankName(String name) => setSetting(_bankNameKey, name);

  // ── Configuración: distribución 50/30/20 ──

  /// Porcentaje de Necesidades del Hogar. Default 50, rango 10–90.
  static int getNeedsPercent() {
    final val = _config.get(_needsPctKey, defaultValue: 50);
    return ((val as num?) ?? 50).toInt().clamp(10, 90);
  }
  static Future<void> setNeedsPercent(int pct) =>
      setSetting(_needsPctKey, pct.clamp(10, 90));

  /// Porcentaje de Gastos Personales. Default 30.
  static int getWantsPercent() {
    final needs = getNeedsPercent();
    final val = _config.get(_wantsPctKey, defaultValue: 30);
    return ((val as num?) ?? 30).toInt().clamp(0, 100 - needs - 5);
  }
  static Future<void> setWantsPercent(int pct) =>
      setSetting(_wantsPctKey, pct.clamp(0, 90));

  /// Porcentaje de Ahorro y Deudas = 100 − necesidades − gastos (calculado).
  static int getSavingsPercent() =>
      (100 - getNeedsPercent() - getWantsPercent()).clamp(0, 100);

  /// Límite de necesidades configurado manualmente (config legacy, se mantiene para compatibilidad).
  static double getLimiteNecesidades() {
    final val = _config.get(_limiteNecesidadesKey,
        defaultValue: FinancialConstants.fondoIntocableDefault);
    return ((val as num?) ?? FinancialConstants.fondoIntocableDefault).toDouble();
  }
  static Future<void> setLimiteNecesidades(double monto) =>
      setSetting(_limiteNecesidadesKey, monto);

  // ── Configuración: frecuencia de ingreso ──

  /// 'weekly' | 'biweekly' | 'monthly'
  static String getFrequency() =>
      (_config.get(_frequencyKey, defaultValue: 'weekly') as String?) ?? 'weekly';
  static Future<void> setFrequency(String freq) => setSetting(_frequencyKey, freq);

  static String getFrequencyLabel() {
    switch (getFrequency()) {
      case 'biweekly': return 'Quincenal';
      case 'monthly':  return 'Mensual';
      default:         return 'Semanal';
    }
  }

  // ── Helpers de período ──

  /// Inicio del período financiero actual (domingo de esta semana / quincena / mes).
  static DateTime getCurrentPeriodStart() {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    switch (getFrequency()) {
      case 'monthly':
        return DateTime(now.year, now.month, 1);
      case 'biweekly':
        final diasDesdeUltimoDomingo = now.weekday % 7;
        final ultimoDomingo = hoy.subtract(Duration(days: diasDesdeUltimoDomingo));
        return ultimoDomingo.subtract(const Duration(days: 7));
      default: // weekly
        return hoy.subtract(Duration(days: now.weekday % 7));
    }
  }

  /// Inicio de la semana calendario actual (domingo 00:00).
  /// Se usa para la checklist de partidas y planes semanales de deuda.
  static DateTime _inicioSemannaActual() {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    return hoy.subtract(Duration(days: now.weekday % 7));
  }

  static DateTime _inicioMesActual() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static String _clavesMes(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  // ══════════════════════════════════════════════════════
  // INGRESOS
  // ══════════════════════════════════════════════════════

  /// Registra un ingreso y lo distribuye según la regla 50/30/20 configurada.
  static Future<Income> registerIncome({
    required double amount,
    required String type,
    String? note,
  }) async {
    final pctNecesidades = getNeedsPercent() / 100.0;
    final montoNecesidades = amount * pctNecesidades;
    final montoGastos = amount - montoNecesidades;

    final ingreso = Income(
      id: generateId(),
      amount: amount,
      type: type,
      date: DateTime.now(),
      necesidades: montoNecesidades,
      gastos: montoGastos,
      note: note,
    );

    await _ingresos.put(ingreso.id, ingreso);
    return ingreso;
  }

  static List<Income> getAllIncomes() {
    final list = _ingresos.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<void> deleteIncome(String id) async {
    await _ingresos.delete(id);
  }

  // ══════════════════════════════════════════════════════
  // DEUDAS
  // ══════════════════════════════════════════════════════

  static Future<Debt> addDebt({
    required String name,
    required String description,
    required DebtCategory category,
    required double totalAmount,
    double monthlyPayment = 0,
    double interestRate = 0,
  }) async {
    final deuda = Debt(
      id: generateId(),
      name: name,
      description: description,
      category: category,
      totalAmount: totalAmount,
      monthlyPayment: monthlyPayment,
      interestRate: interestRate,
      createdAt: DateTime.now(),
    );
    await _deudas.put(deuda.id, deuda);
    return deuda;
  }

  static List<Debt> getAllDebts() =>
      _deudas.values.where((d) => d.isActive).toList();

  static List<Debt> getDebtsByCategory(DebtCategory category) =>
      getAllDebts().where((d) => d.category == category).toList();

  static Future<DebtPayment> makePayment({
    required String debtId,
    required double amount,
    String? note,
  }) async {
    final deuda = _deudas.get(debtId);
    if (deuda == null) throw Exception('Deuda no encontrada');

    final montoEfectivo = amount.clamp(0.0, deuda.remainingAmount);
    if (montoEfectivo <= 0) throw Exception('La deuda ya está liquidada');
    deuda.paidAmount += montoEfectivo;
    deuda.lastPaymentDate = DateTime.now();
    await deuda.save();

    final pago = DebtPayment(
      id: generateId(),
      debtId: debtId,
      amount: montoEfectivo,
      date: DateTime.now(),
      note: note,
    );
    await _pagos.put(pago.id, pago);
    return pago;
  }

  static List<DebtPayment> getPaymentsForDebt(String debtId) =>
      _pagos.values.where((p) => p.debtId == debtId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  static Future<void> deleteDebt(String id) async {
    final deuda = _deudas.get(id);
    if (deuda != null) {
      deuda.isActive = false;
      await deuda.save();
    }
  }

  static Future<void> updateDebt(Debt debt) async => await debt.save();

  // ── Planes semanales de deuda ──

  static String _clavePlanSemanal(String debtId) => 'weekly_plan_$debtId';

  static Future<void> splitDebtIntoWeeklyPlan({
    required String debtId,
    required int weeks,
    required int dueWeekday,
  }) async {
    final deuda = _deudas.get(debtId);
    if (deuda == null) throw Exception('Deuda no encontrada');
    if (weeks <= 0) throw Exception('Número de semanas inválido');

    final montoPorSemana = deuda.remainingAmount / weeks;
    await _config.put(_clavePlanSemanal(debtId), {
      'debtId': debtId,
      'weeks': weeks,
      'weeklyAmount': montoPorSemana,
      'dueWeekday': dueWeekday,
      'createdAt': DateTime.now().toIso8601String(),
      'active': true,
    });
  }

  static Map<String, dynamic>? getDebtWeeklyPlan(String debtId) {
    final raw = _config.get(_clavePlanSemanal(debtId));
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  static Future<void> removeDebtWeeklyPlan(String debtId) async =>
      await _config.delete(_clavePlanSemanal(debtId));

  static double getDebtPaidThisWeek(String debtId) {
    final semanaInicio = _inicioSemannaActual();
    return _pagos.values
        .where((p) => p.debtId == debtId && p.date.isAfter(semanaInicio))
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  static bool isDebtWeeklyPaymentPending(Debt debt) {
    final plan = getDebtWeeklyPlan(debt.id);
    if (plan == null || plan['active'] != true) return false;
    final diaVencimiento = (plan['dueWeekday'] as int?) ?? DateTime.friday;
    if (DateTime.now().weekday < diaVencimiento) return false;
    final montoPorSemana = (plan['weeklyAmount'] as num?)?.toDouble() ?? 0;
    return getDebtPaidThisWeek(debt.id) + 0.01 < montoPorSemana;
  }

  // ══════════════════════════════════════════════════════
  // GASTOS FIJOS
  // ══════════════════════════════════════════════════════

  static Future<FixedExpense> addFixedExpense({
    required String name,
    required double amount,
    required int dueDay,
  }) async {
    final gasto = FixedExpense(
      id: generateId(),
      name: name,
      amount: amount,
      dueDay: dueDay.clamp(1, 28),
    );
    await _gastosFijos.put(gasto.id, gasto);
    return gasto;
  }

  static List<FixedExpense> getAllFixedExpenses() =>
      _gastosFijos.values.where((e) => e.isActive).toList()
        ..sort((a, b) => a.dueDay.compareTo(b.dueDay));

  static List<FixedExpensePayment> getAllFixedExpensePayments(String expenseId) =>
      _pagosFijos.values
          .where((p) => p.expenseId == expenseId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  static Future<void> deleteFixedExpense(String id) async {
    final gasto = _gastosFijos.get(id);
    if (gasto != null) {
      gasto.isActive = false;
      await gasto.save();
    }
  }

  static bool isFixedExpensePaidThisMonth(String expenseId) {
    final mesActual = _clavesMes(DateTime.now());
    return _pagosFijos.values.any(
        (p) => p.expenseId == expenseId && _clavesMes(p.date) == mesActual);
  }

  static Future<void> registerFixedExpensePayment({
    required String expenseId,
    String? note,
  }) async {
    final gasto = _gastosFijos.get(expenseId);
    if (gasto == null) throw Exception('Gasto fijo no encontrado');
    if (isFixedExpensePaidThisMonth(expenseId)) return;

    final pago = FixedExpensePayment(
      id: generateId(),
      expenseId: expenseId,
      amount: gasto.amount,
      date: DateTime.now(),
      note: note,
    );
    await _pagosFijos.put(pago.id, pago);
  }

  static List<FixedExpense> getPendingFixedExpensesThisMonth() {
    final hoy = DateTime.now();
    return getAllFixedExpenses().where((e) {
      if (e.dueDay > hoy.day) return false;
      return !isFixedExpensePaidThisMonth(e.id);
    }).toList();
  }

  // ══════════════════════════════════════════════════════
  // PARTIDAS DE NECESIDADES (checklist semanal)
  // ══════════════════════════════════════════════════════

  /// Plantillas de partidas configuradas por el usuario.
  /// Si no hay ninguna configurada, usa los valores por defecto.
  static Map<String, double> getPlantillasPartidas() {
    final raw = _config.get(_plantillasKey);
    if (raw is Map && raw.isNotEmpty) {
      return Map.fromEntries(
        raw.entries.map(
          (e) => MapEntry(e.key as String, ((e.value as num?)?.toDouble()) ?? 0.0),
        ),
      );
    }
    return Map.from(FinancialConstants.fondoItemDefaults);
  }

  /// Guarda las plantillas de partidas para nuevas semanas.
  static Future<void> setPlantillasPartidas(Map<String, double> plantillas) async {
    await setSetting(
      _plantillasKey,
      Map<String, dynamic>.fromEntries(
        plantillas.entries.map((e) => MapEntry(e.key, e.value)),
      ),
    );
  }

  /// Devuelve las partidas de la semana actual, creándolas si no existen.
  static Future<List<FondoItem>> getOrCreatePartidas() async {
    final semanaInicio = _inicioSemannaActual();
    final clavesSemana =
        '${semanaInicio.year}-${semanaInicio.month}-${semanaInicio.day}';

    final existentes = _partidas.values.where((item) {
      final k =
          '${item.weekStart.year}-${item.weekStart.month}-${item.weekStart.day}';
      return k == clavesSemana;
    }).toList();

    if (existentes.isNotEmpty) return existentes;

    // Crear desde plantillas
    final plantillas = getPlantillasPartidas();
    final nuevas = <FondoItem>[];
    for (final entry in plantillas.entries) {
      final item = FondoItem(
        id: generateId(),
        name: entry.key,
        targetAmount: entry.value,
        weekStart: semanaInicio,
      );
      await _partidas.put(item.id, item);
      nuevas.add(item);
    }
    return nuevas;
  }

  /// Alterna el estado pagado/pendiente de una partida.
  static Future<void> togglePartida(String id) async {
    final item = _partidas.get(id);
    if (item == null) return;
    item.isPaid = !item.isPaid;
    item.paidAt = item.isPaid ? DateTime.now() : null;
    await item.save();
  }

  /// Actualiza nombre y/o monto de una partida.
  static Future<void> updatePartida(String id,
      {String? name, double? amount}) async {
    final item = _partidas.get(id);
    if (item == null) return;
    if (name != null && name.isNotEmpty) item.name = name;
    if (amount != null && amount > 0) item.targetAmount = amount;
    await item.save();
  }

  /// Agrega una partida nueva a la semana actual.
  static Future<FondoItem> addPartida({
    required String name,
    required double amount,
  }) async {
    final semanaInicio = _inicioSemannaActual();
    final item = FondoItem(
      id: generateId(),
      name: name,
      targetAmount: amount,
      weekStart: semanaInicio,
    );
    await _partidas.put(item.id, item);
    return item;
  }

  /// Elimina una partida de la semana actual.
  static Future<void> deletePartida(String id) async =>
      await _partidas.delete(id);

  // ══════════════════════════════════════════════════════
  // FONDOS DE AHORRO
  // ══════════════════════════════════════════════════════

  static List<SavingsFund> getAllSavingsFunds() =>
      _fondosAhorro.values.where((f) => f.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  static Future<SavingsFund> createSavingsFund({
    required String name,
    required String type,
    double targetAmount = 0,
    String? description,
  }) async {
    final fondo = SavingsFund(
      id: generateId(),
      name: name,
      type: type,
      targetAmount: targetAmount,
      description: description,
      createdAt: DateTime.now(),
    );
    await _fondosAhorro.put(fondo.id, fondo);
    return fondo;
  }

  /// Deposita [amount] al fondo desde el presupuesto de ahorro (20%).
  static Future<void> depositToFund({
    required String fundId,
    required double amount,
    String? note,
  }) async {
    final fondo = _fondosAhorro.get(fundId);
    if (fondo == null) throw Exception('Fondo no encontrado');

    fondo.balance += amount;
    await fondo.save();

    final movimiento = SavingsMovement(
      id: generateId(),
      fundId: fundId,
      amount: amount,
      isDeposit: true,
      note: note,
      date: DateTime.now(),
    );
    await _movimientosAhorro.put(movimiento.id, movimiento);
  }

  /// Retira [amount] del fondo, devolviendo el saldo al presupuesto de ahorro.
  static Future<void> withdrawFromFund({
    required String fundId,
    required double amount,
    String? note,
  }) async {
    final fondo = _fondosAhorro.get(fundId);
    if (fondo == null) throw Exception('Fondo no encontrado');
    if (fondo.balance < amount) throw Exception('Saldo insuficiente en el fondo');

    fondo.balance -= amount;
    await fondo.save();

    final movimiento = SavingsMovement(
      id: generateId(),
      fundId: fundId,
      amount: amount,
      isDeposit: false,
      note: note,
      date: DateTime.now(),
    );
    await _movimientosAhorro.put(movimiento.id, movimiento);
  }

  static List<SavingsMovement> getMovementsForFund(String fundId) =>
      _movimientosAhorro.values
          .where((m) => m.fundId == fundId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Elimina (soft-delete) un fondo. Si tiene saldo, crea un retiro
  /// para que el presupuesto de ahorro quede correctamente restaurado.
  static Future<void> deleteSavingsFund(String id) async {
    final fondo = _fondosAhorro.get(id);
    if (fondo == null) return;

    if (fondo.balance > 0) {
      final movimiento = SavingsMovement(
        id: generateId(),
        fundId: id,
        amount: fondo.balance,
        isDeposit: false,
        note: 'Fondo eliminado — saldo devuelto al presupuesto de ahorro',
        date: DateTime.now(),
      );
      await _movimientosAhorro.put(movimiento.id, movimiento);
    }

    fondo.isActive = false;
    await fondo.save();
  }

  /// Suma total de saldos en todos los fondos activos.
  static double getTotalSavingsBalance() =>
      getAllSavingsFunds().fold(0.0, (sum, f) => sum + f.balance);

  // ══════════════════════════════════════════════════════
  // CÁLCULOS FINANCIEROS
  // ══════════════════════════════════════════════════════

  /// Saldo total en cuenta (ingresos − pagos de deudas − gastos fijos pagados).
  /// Los fondos de ahorro NO se restan porque siguen siendo dinero en tu cuenta.
  static double getSaldoTotal() {
    final totalIngresos = _ingresos.values.fold(0.0, (s, i) => s + i.amount);
    final totalPagos = _pagos.values.fold(0.0, (s, p) => s + p.amount)
        + _pagosFijos.values.fold(0.0, (s, f) => s + f.amount);
    return totalIngresos - totalPagos;
  }

  /// Dinero disponible para gastos personales en el período actual.
  /// Equivale al % de Gastos Personales del ingreso del período.
  /// No disminuye por ahorros ni pagos de deudas — esos salen de [getAhorroDisponible].
  static double getGastosDisponibles() {
    final inicioP = getCurrentPeriodStart();
    final pctGastos = getWantsPercent() / 100.0;

    return _ingresos.values
        .where((i) => i.date.isAfter(inicioP))
        .fold(0.0, (s, i) => s + i.amount * pctGastos)
        .clamp(0.0, double.infinity);
  }

  /// Dinero disponible para ahorro y pago de deudas en el período actual.
  /// Equivale al % de Ahorro y Deudas del ingreso, menos lo ya comprometido.
  static double getAhorroDisponible() {
    final inicioP = getCurrentPeriodStart();
    final pctAhorro = getSavingsPercent() / 100.0;

    double total = _ingresos.values
        .where((i) => i.date.isAfter(inicioP))
        .fold(0.0, (s, i) => s + i.amount * pctAhorro);

    for (final m in _movimientosAhorro.values) {
      if (m.date.isAfter(inicioP)) {
        total += m.isDeposit ? -m.amount : m.amount;
      }
    }
    for (final p in _pagos.values) {
      if (p.date.isAfter(inicioP)) total -= p.amount;
    }

    return total.clamp(0.0, double.infinity);
  }

  /// Total de ingresos asignados a Necesidades del Hogar en el período actual.
  /// Es el % de Necesidades multiplicado por cada ingreso registrado en el período.
  static double getNecesidadesAsignadas() {
    final inicioP = getCurrentPeriodStart();
    return _ingresos.values
        .where((i) => i.date.isAfter(inicioP))
        .fold(0.0, (s, i) => s + i.necesidades);
  }

  /// Devuelve true si el ingreso asignado a Necesidades cubre el total
  /// de las partidas planificadas para esta semana.
  static bool isNecesidadesCubiertas() {
    final asignado = getNecesidadesAsignadas();
    if (asignado <= 0) return false;

    final semanaInicio = _inicioSemannaActual();
    final clavesSemana =
        '${semanaInicio.year}-${semanaInicio.month}-${semanaInicio.day}';
    final partidasSemana = _partidas.values.where((item) {
      final k =
          '${item.weekStart.year}-${item.weekStart.month}-${item.weekStart.day}';
      return k == clavesSemana;
    }).toList();

    if (partidasSemana.isEmpty) return true;
    final totalNecesario =
        partidasSemana.fold(0.0, (s, i) => s + i.targetAmount);
    return asignado >= totalNecesario;
  }

  // ══════════════════════════════════════════════════════
  // RESÚMENES FINANCIEROS
  // ══════════════════════════════════════════════════════

  static MonthlyBalanceSummary getCurrentMonthSummary() {
    final inicioMes = _inicioMesActual();

    final ingresos = _ingresos.values
        .where((i) => i.date.isAfter(inicioMes))
        .fold(0.0, (s, i) => s + i.amount);

    final pagosDeuda = _pagos.values
        .where((p) => p.date.isAfter(inicioMes))
        .fold(0.0, (s, p) => s + p.amount);

    final pagosFijosMes = _pagosFijos.values
        .where((f) => f.date.isAfter(inicioMes))
        .fold(0.0, (s, f) => s + f.amount);

    double ahorroNeto = 0;
    for (final m in _movimientosAhorro.values) {
      if (m.date.isAfter(inicioMes)) {
        ahorroNeto += m.isDeposit ? m.amount : -m.amount;
      }
    }

    return MonthlyBalanceSummary(
      incomes: ingresos,
      debtPayments: pagosDeuda,
      fixedExpenses: pagosFijosMes,
      savingsNet: ahorroNeto,
      cashResult: ingresos - pagosDeuda - pagosFijosMes - ahorroNeto,
    );
  }

  /// Resumen financiero de un mes específico.
  static MonthlyBalanceSummary getMonthSummaryByDate(int year, int month) {
    final inicio = DateTime(year, month, 1);
    final fin = month < 12
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);

    bool enRango(DateTime d) => !d.isBefore(inicio) && d.isBefore(fin);

    final ingresos = _ingresos.values
        .where((i) => enRango(i.date))
        .fold(0.0, (s, i) => s + i.amount);

    final pagosDeuda = _pagos.values
        .where((p) => enRango(p.date))
        .fold(0.0, (s, p) => s + p.amount);

    final pagosFijosMes = _pagosFijos.values
        .where((f) => enRango(f.date))
        .fold(0.0, (s, f) => s + f.amount);

    double ahorroNeto = 0;
    for (final m in _movimientosAhorro.values) {
      if (enRango(m.date)) ahorroNeto += m.isDeposit ? m.amount : -m.amount;
    }

    return MonthlyBalanceSummary(
      incomes: ingresos,
      debtPayments: pagosDeuda,
      fixedExpenses: pagosFijosMes,
      savingsNet: ahorroNeto,
      cashResult: ingresos - pagosDeuda - pagosFijosMes - ahorroNeto,
    );
  }

  /// Lista de meses (descendente) que tienen al menos un movimiento registrado.
  static List<DateTime> getMonthsWithData() {
    final vistos = <String, DateTime>{};
    void registrar(DateTime d) =>
        vistos['${d.year}-${d.month}'] ??= DateTime(d.year, d.month, 1);

    for (final i in _ingresos.values)    { registrar(i.date); }
    for (final p in _pagos.values)       { registrar(p.date); }
    for (final f in _pagosFijos.values)  { registrar(f.date); }
    return vistos.values.toList()..sort((a, b) => b.compareTo(a));
  }

  // ══════════════════════════════════════════════════════
  // PENDIENTES
  // ══════════════════════════════════════════════════════

  static List<PendingInfoItem> getPendingInfoItems() {
    final resultado = <PendingInfoItem>[];

    for (final deuda in getAllDebts()) {
      final plan = getDebtWeeklyPlan(deuda.id);
      if (plan == null || plan['active'] != true) continue;

      final diaVencimiento = (plan['dueWeekday'] as int?) ?? DateTime.friday;
      final montoPorSemana = (plan['weeklyAmount'] as num?)?.toDouble() ?? 0;
      final pagado = getDebtPaidThisWeek(deuda.id);
      final pendiente =
          (montoPorSemana - pagado).clamp(0.0, double.infinity);

      if (DateTime.now().weekday >= diaVencimiento && pendiente > 0) {
        resultado.add(PendingInfoItem(
          title: deuda.name,
          subtitle: 'Pago semanal pendiente',
          amount: pendiente,
          kind: PendingKind.weeklyDebt,
        ));
      }
    }

    for (final gasto in getPendingFixedExpensesThisMonth()) {
      resultado.add(PendingInfoItem(
        title: gasto.name,
        subtitle: 'Gasto fijo pendiente (día ${gasto.dueDay})',
        amount: gasto.amount,
        kind: PendingKind.fixedExpense,
        refId: gasto.id,
      ));
    }

    resultado.sort((a, b) => b.amount.compareTo(a.amount));
    return resultado;
  }

  // ══════════════════════════════════════════════════════
  // TOTALES DE DEUDA
  // ══════════════════════════════════════════════════════

  static double getTotalDebtRemaining() =>
      getAllDebts().fold(0.0, (s, d) => s + d.remainingAmount);

  static double getTotalDebtByCategory(DebtCategory category) =>
      getDebtsByCategory(category).fold(0.0, (s, d) => s + d.remainingAmount);

  // ══════════════════════════════════════════════════════
  // CONFIGURACIÓN GENÉRICA
  // ══════════════════════════════════════════════════════

  static Future<void> setSetting(String key, dynamic value) async =>
      await _config.put(key, value);

  static dynamic getSetting(String key, {dynamic defaultValue}) =>
      _config.get(key, defaultValue: defaultValue);

  static String? getGeminiApiKey() =>
      _config.get('gemini_api_key') as String?;

  static Future<void> setGeminiApiKey(String key) async =>
      await _config.put('gemini_api_key', key);
}

// ══════════════════════════════════════════════════════
// VALUE OBJECTS
// ══════════════════════════════════════════════════════

enum PendingKind { weeklyDebt, fixedExpense }

class PendingInfoItem {
  final String title;
  final String subtitle;
  final double amount;
  final PendingKind kind;
  final String? refId;

  const PendingInfoItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.kind,
    this.refId,
  });
}

class MonthlyBalanceSummary {
  final double incomes;
  final double debtPayments;
  final double fixedExpenses;
  final double savingsNet;
  final double cashResult;

  const MonthlyBalanceSummary({
    required this.incomes,
    required this.debtPayments,
    required this.fixedExpenses,
    required this.savingsNet,
    required this.cashResult,
  });
}
