import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/refugio_theme.dart';
import '../widgets/tactical_widgets.dart';
import '../services/database_service.dart';
import '../models/debt.dart';

/// Pantalla 3: Plan de Liquidación (Gestión de Pasivos)
class FrentesDeBatallaScreen extends StatefulWidget {
  final VoidCallback? onPaymentMade;

  const FrentesDeBatallaScreen({super.key, this.onPaymentMade});

  @override
  State<FrentesDeBatallaScreen> createState() => _FrentesDeBatallaScreenState();
}

class _FrentesDeBatallaScreenState extends State<FrentesDeBatallaScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  final _categories = [
    _CategoryConfig(
      category: DebtCategory.deudaDeHonor,
      title: 'Compromisos Personales',
      subtitle: 'Préstamos familiares o amigos — Prioridad alta',
      color: RefugioTheme.debtHonor,
      icon: Icons.people_rounded,
    ),
    _CategoryConfig(
      category: DebtCategory.basuraFinanciera,
      title: 'Pasivos Prioritarios',
      subtitle: 'Deudas de alto costo — Liquidación estratégica',
      color: RefugioTheme.debtBasura,
      icon: Icons.priority_high_rounded,
    ),
    _CategoryConfig(
      category: DebtCategory.lineaEstrategica,
      title: 'Líneas Estratégicas',
      subtitle: 'Herramientas de operación — Mantenimiento',
      color: RefugioTheme.debtLinea,
      icon: Icons.build_circle_rounded,
    ),
    _CategoryConfig(
      category: DebtCategory.laCongeladora,
      title: 'En Pausa Estratégica',
      subtitle: 'Sin actividad por ahora — Solo monitoreo',
      color: RefugioTheme.debtCongeladora,
      icon: Icons.pause_circle_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan de Liquidación',
                  style: RefugioTextStyles.heading.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestión de pasivos y metas',
                  style: RefugioTextStyles.label,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Botones de acción ──
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAddDebtDialog(),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Nuevo pasivo'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAddDebtDialog(isMeta: true),
                icon: const Icon(Icons.flag_rounded, size: 18),
                label: const Text('Nueva meta'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddFixedExpenseDialog(),
            icon: const Icon(Icons.view_agenda_rounded, size: 16),
            label: const Text('Agregar gasto fijo mensual'),
            style: OutlinedButton.styleFrom(
              foregroundColor: RefugioTheme.debtLinea,
              side: const BorderSide(color: RefugioTheme.debtLinea),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Categorías ──
        ..._categories.map((config) => _buildCategorySection(config)),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCategorySection(_CategoryConfig config) {
    final debts = DatabaseService.getDebtsByCategory(config.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RefugioCard(
        borderColor: config.color,
        headerLabel: config.title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.subtitle,
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 12,
                color: config.color.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            if (debts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: RefugioTheme.textMuted, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Sin pasivos en esta categoría',
                      style: TextStyle(
                        fontFamily: RefugioTheme.fontFamily,
                        fontSize: 13,
                        color: RefugioTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...debts.map((debt) => _buildDebtItem(debt, config)),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtItem(Debt debt, _CategoryConfig config) {
    final isPaused = debt.category == DebtCategory.laCongeladora;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: RefugioTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RefugioTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    debt.name,
                    style: RefugioTextStyles.subtitle.copyWith(
                      color: config.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (debt.isUsurera)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: RefugioTheme.salmon.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: RefugioTheme.salmon.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'Alto costo',
                      style: TextStyle(
                        fontFamily: RefugioTheme.fontFamily,
                        fontSize: 10,
                        color: RefugioTheme.salmon,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: RefugioTheme.textMuted, size: 18),
                  color: RefugioTheme.surface,
                  onSelected: (value) {
                    if (value == 'split') {
                      _showSplitDebtDialog(debt);
                    } else if (value == 'remove_split') {
                      DatabaseService.removeDebtWeeklyPlan(debt.id).then((_) {
                        if (!mounted) return;
                        setState(() {});
                      });
                    } else if (value == 'delete') {
                      _confirmDelete(debt);
                    }
                  },
                  itemBuilder: (context) {
                    final hasPlan = DatabaseService.getDebtWeeklyPlan(debt.id) != null;
                    return [
                    const PopupMenuItem(
                      value: 'split',
                      child: Text('Dividir en pagos semanales', style: TextStyle(
                        fontFamily: RefugioTheme.fontFamily,
                        fontSize: 13,
                      )),
                    ),
                    if (hasPlan)
                      const PopupMenuItem(
                        value: 'remove_split',
                        child: Text('Quitar plan semanal', style: TextStyle(
                          fontFamily: RefugioTheme.fontFamily,
                          fontSize: 13,
                        )),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar', style: TextStyle(
                        fontFamily: RefugioTheme.fontFamily,
                        fontSize: 13,
                        color: RefugioTheme.salmon,
                      )),
                    ),
                  ];
                  },
                ),
              ],
            ),
            if (debt.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                debt.description,
                style: TextStyle(
                  fontFamily: RefugioTheme.fontFamily,
                  fontSize: 12,
                  color: RefugioTheme.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildWeeklyPlanInfo(debt),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Restante', style: RefugioTextStyles.label),
                    Text(
                      _currencyFormat.format(debt.remainingAmount),
                      style: RefugioTextStyles.moneyMedium.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                if (!isPaused)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total', style: RefugioTextStyles.label),
                      Text(
                        _currencyFormat.format(debt.totalAmount),
                        style: RefugioTextStyles.body.copyWith(
                          color: RefugioTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (!isPaused) ...[
              const SizedBox(height: 12),
              RefugioProgressBar(
                progress: debt.progressPercent,
                color: config.color,
                label: 'Progreso',
                height: 8,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(debt),
                  icon: const Icon(Icons.payments_rounded, size: 16),
                  label: const Text('Registrar pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.color.withValues(alpha: 0.12),
                    foregroundColor: config.color,
                    side: BorderSide(color: config.color.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RefugioTheme.debtCongeladora.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pause_circle_rounded, color: RefugioTheme.debtCongeladora, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'En pausa — solo monitoreo, no afecta tu flujo semanal',
                        style: TextStyle(
                          fontFamily: RefugioTheme.fontFamily,
                          fontSize: 11,
                          color: RefugioTheme.debtCongeladora,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyPlanInfo(Debt debt) {
    final plan = DatabaseService.getDebtWeeklyPlan(debt.id);
    if (plan == null || plan['active'] != true) {
      return Row(
        children: [
          Icon(Icons.calendar_today_outlined, color: RefugioTheme.textMuted.withValues(alpha: 0.6), size: 13),
          const SizedBox(width: 6),
          Text(
            'Sin plan semanal',
            style: RefugioTextStyles.label.copyWith(fontSize: 11),
          ),
        ],
      );
    }

    final weeklyAmount = (plan['weeklyAmount'] as num?)?.toDouble() ?? 0;
    final dueWeekday = (plan['dueWeekday'] as int?) ?? DateTime.friday;
    final paidThisWeek = DatabaseService.getDebtPaidThisWeek(debt.id);
    final pending = (weeklyAmount - paidThisWeek).clamp(0.0, double.infinity);
    final isPending = DateTime.now().weekday >= dueWeekday && pending > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPending
            ? RefugioTheme.salmon.withValues(alpha: 0.10)
            : RefugioTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPending
              ? RefugioTheme.salmon.withValues(alpha: 0.35)
              : RefugioTheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            size: 14,
            color: isPending ? RefugioTheme.salmon : RefugioTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isPending
                  ? 'Pendiente semanal: ${_currencyFormat.format(pending)}'
                  : 'Plan semanal: ${_currencyFormat.format(weeklyAmount)} · ${_weekdayLabel(dueWeekday)}',
              style: RefugioTextStyles.label.copyWith(
                fontSize: 11,
                color: isPending ? RefugioTheme.salmon : RefugioTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSplitDebtDialog(Debt debt) {
    final weeksCtrl = TextEditingController(text: '4');
    int dueWeekday = DateTime.friday;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final weeks = int.tryParse(weeksCtrl.text.trim()) ?? 4;
          final weeklyPreview = weeks > 0 ? debt.remainingAmount / weeks : debt.remainingAmount;

          return AlertDialog(
            title: Text('Dividir: ${debt.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restante: ${_currencyFormat.format(debt.remainingAmount)}',
                  style: RefugioTextStyles.subtitle,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weeksCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Número de semanas',
                    hintText: 'Ej. 4',
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: dueWeekday,
                  decoration: const InputDecoration(labelText: 'Día límite semanal'),
                  items: const [
                    DropdownMenuItem(value: DateTime.monday, child: Text('Lunes')),
                    DropdownMenuItem(value: DateTime.tuesday, child: Text('Martes')),
                    DropdownMenuItem(value: DateTime.wednesday, child: Text('Miércoles')),
                    DropdownMenuItem(value: DateTime.thursday, child: Text('Jueves')),
                    DropdownMenuItem(value: DateTime.friday, child: Text('Viernes')),
                    DropdownMenuItem(value: DateTime.saturday, child: Text('Sábado')),
                    DropdownMenuItem(value: DateTime.sunday, child: Text('Domingo')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => dueWeekday = value);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Pago semanal sugerido: ${_currencyFormat.format(weeklyPreview)}',
                  style: RefugioTextStyles.label.copyWith(
                    color: RefugioTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: RefugioTheme.textMuted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final weeks = int.tryParse(weeksCtrl.text.trim());
                  if (weeks == null || weeks <= 0) return;
                  await DatabaseService.splitDebtIntoWeeklyPlan(
                    debtId: debt.id,
                    weeks: weeks,
                    dueWeekday: dueWeekday,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  setState(() {});
                },
                child: const Text('Guardar plan'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lunes';
      case DateTime.tuesday:
        return 'Martes';
      case DateTime.wednesday:
        return 'Miércoles';
      case DateTime.thursday:
        return 'Jueves';
      case DateTime.friday:
        return 'Viernes';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return 'Día';
    }
  }

  void _showPaymentDialog(Debt debt) {
    final controller = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Pago a: ${debt.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Restante: ${_currencyFormat.format(debt.remainingAmount)}',
              style: RefugioTextStyles.subtitle,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monto del pago',
                prefixText: '\$ ',
                suffixText: 'MXN',
              ),
              autofocus: true,
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 22,
                color: RefugioTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
              ),
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 14,
                color: RefugioTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: RefugioTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());
              if (amount == null || amount <= 0) return;

              Navigator.pop(dialogContext);
              await DatabaseService.makePayment(
                debtId: debt.id,
                amount: amount,
                note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
              );
              if (!mounted) return;
              setState(() {});
              widget.onPaymentMade?.call();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pago registrado: ${_currencyFormat.format(amount)} a ${debt.name}',
                  ),
                ),
              );
            },
            child: const Text('Confirmar pago'),
          ),
        ],
      ),
    );
  }

  void _showAddDebtDialog({bool isMeta = false}) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final monthlyController = TextEditingController();
    final interestController = TextEditingController();
    DebtCategory selectedCategory = DebtCategory.deudaDeHonor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isMeta ? 'Nueva meta de ahorro' : 'Nuevo pasivo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: isMeta ? 'Nombre de la meta' : 'Nombre del pasivo',
                    hintText: isMeta ? 'Ej: Fondo de emergencia' : 'Ej: Papá, Kueski...',
                  ),
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 14,
                    color: RefugioTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Detalles...',
                  ),
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 14,
                    color: RefugioTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: isMeta ? 'Monto objetivo' : 'Monto total',
                    prefixText: '\$ ',
                    suffixText: 'MXN',
                  ),
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 18,
                    color: RefugioTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isMeta) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DebtCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                    ),
                    dropdownColor: RefugioTheme.surface,
                    items: DebtCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(
                          _categoryLabel(cat),
                          style: TextStyle(
                            fontFamily: RefugioTheme.fontFamily,
                            fontSize: 13,
                            color: RefugioTheme.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (selectedCategory != DebtCategory.laCongeladora)
                    TextField(
                      controller: monthlyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Pago mensual (opcional)',
                        prefixText: '\$ ',
                      ),
                      style: TextStyle(
                        fontFamily: RefugioTheme.fontFamily,
                        fontSize: 14,
                        color: RefugioTheme.textPrimary,
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: interestController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Tasa de interés % (opcional)',
                      suffixText: '%',
                    ),
                    style: TextStyle(
                      fontFamily: RefugioTheme.fontFamily,
                      fontSize: 14,
                      color: RefugioTheme.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: RefugioTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text.trim());

                if (name.isEmpty || amount == null || amount <= 0) return;

                final interest = double.tryParse(interestController.text.trim()) ?? 0;

                // Alerta de alto costo
                if (interest > 100) {
                  final proceed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Atención'),
                      content: Text(
                        'Tasa del ${interest.toStringAsFixed(1)}% detectada.\n\n'
                        'Esto se clasifica como pasivo prioritario por su alto costo.\n'
                        '¿Confirmar registro?',
                        style: RefugioTextStyles.alertSalmon,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RefugioTheme.salmonDim,
                          ),
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  );
                  if (proceed != true) return;
                }

                if (!context.mounted) return;
                Navigator.pop(context);

                await DatabaseService.addDebt(
                  name: name,
                  description: descController.text.trim(),
                  category: isMeta ? DebtCategory.lineaEstrategica : selectedCategory,
                  totalAmount: amount,
                  monthlyPayment: double.tryParse(monthlyController.text.trim()) ?? 0,
                  interestRate: interest,
                );

                setState(() {});
                widget.onPaymentMade?.call();
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFixedExpenseDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    int dueDay = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar gasto fijo mensual'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del gasto',
                    hintText: 'Ej: Internet, Renta, Spotify...',
                  ),
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 14,
                    color: RefugioTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monto mensual',
                    prefixText: '\$ ',
                    suffixText: 'MXN',
                  ),
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 18,
                    color: RefugioTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: dueDay,
                  decoration: const InputDecoration(
                    labelText: 'Día de vencimiento (1-28)',
                  ),
                  dropdownColor: RefugioTheme.surface,
                  items: List.generate(28, (i) => i + 1)
                      .map((day) => DropdownMenuItem(
                            value: day,
                            child: Text(
                              'Día $day del mes',
                              style: TextStyle(
                                fontFamily: RefugioTheme.fontFamily,
                                fontSize: 13,
                                color: RefugioTheme.textPrimary,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => dueDay = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: RefugioTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text.trim());

                if (name.isEmpty || amount == null || amount <= 0) return;

                if (!context.mounted) return;
                Navigator.pop(context);

                await DatabaseService.addFixedExpense(
                  name: name,
                  amount: amount,
                  dueDay: dueDay,
                );

                setState(() {});
                widget.onPaymentMade?.call();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Eliminar "${debt.name}" de tus pasivos?',
          style: RefugioTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: RefugioTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseService.deleteDebt(debt.id);
              setState(() {});
              widget.onPaymentMade?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RefugioTheme.salmonDim,
              foregroundColor: RefugioTheme.salmon,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(DebtCategory cat) {
    switch (cat) {
      case DebtCategory.deudaDeHonor:
        return 'Compromiso Personal';
      case DebtCategory.lineaEstrategica:
        return 'Línea Estratégica';
      case DebtCategory.basuraFinanciera:
        return 'Pasivo Prioritario';
      case DebtCategory.laCongeladora:
        return 'En Pausa Estratégica';
    }
  }
}

class _CategoryConfig {
  final DebtCategory category;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _CategoryConfig({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}
