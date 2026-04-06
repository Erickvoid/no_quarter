import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/refugio_theme.dart';
import '../widgets/tactical_widgets.dart';
import '../services/database_service.dart';
import '../models/constants.dart';
import '../models/debt.dart';
import '../models/fondo_item.dart';

/// Pantalla 1: Panel de Control (Dashboard)
class CentroDeMandoScreen extends StatefulWidget {
  const CentroDeMandoScreen({super.key});

  @override
  State<CentroDeMandoScreen> createState() => _CentroDeMandoScreenState();
}

class _CentroDeMandoScreenState extends State<CentroDeMandoScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  List<FondoItem> _fondoItems = [];

  @override
  void initState() {
    super.initState();
    _loadFondoItems();
  }

  Future<void> _loadFondoItems() async {
    final items = await DatabaseService.getOrCreateWeeklyFondoItems();
    if (mounted) setState(() => _fondoItems = items);
  }

  @override
  Widget build(BuildContext context) {
    final saldoTotal = DatabaseService.getSaldoTotal();
    final titaniumSecured = DatabaseService.isTitaniumSecured();
    final titaniumAmount = DatabaseService.getBloqueDeTitanioThisWeek();
    final capitalLibre = DatabaseService.getMunicionLibreTotal();
    final totalDebt = DatabaseService.getTotalDebtRemaining();

    return RefreshIndicator(
      color: RefugioTheme.primary,
      backgroundColor: RefugioTheme.surface,
      onRefresh: () async {
        await _loadFondoItems();
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),

          // ── Saldo Total BBVA ──
          RefugioCard(
            borderColor: RefugioTheme.primary,
            headerLabel: 'Saldo Total BBVA',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currencyFormat.format(saldoTotal),
                  style: RefugioTextStyles.moneyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'MXN',
                  style: RefugioTextStyles.label,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Fondo Intocable ──
          RefugioCard(
            borderColor: titaniumSecured ? RefugioTheme.primary : RefugioTheme.salmon,
            headerLabel: 'Fondo Intocable',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      titaniumSecured ? Icons.verified_rounded : Icons.info_outline_rounded,
                      color: titaniumSecured ? RefugioTheme.primary : RefugioTheme.salmon,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titaniumSecured ? 'Asegurado' : 'Incompleto',
                            style: titaniumSecured
                                ? RefugioTextStyles.heading.copyWith(fontSize: 16, color: RefugioTheme.primary)
                                : RefugioTextStyles.alertSalmon.copyWith(fontSize: 16),
                          ),
                          Text(
                            '${_currencyFormat.format(titaniumAmount)} / ${_currencyFormat.format(FinancialConstants.bloqueDeTitanio)}',
                            style: RefugioTextStyles.subtitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RefugioProgressBar(
                  progress: titaniumAmount / FinancialConstants.bloqueDeTitanio,
                  color: titaniumSecured ? RefugioTheme.primary : RefugioTheme.salmon,
                  label: 'Cobertura',
                  height: 10,
                ),
                const SizedBox(height: 16),
                _buildFundChecklist(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Capital Libre ──
          RefugioCard(
            borderColor: capitalLibre > 0 ? RefugioTheme.primary : RefugioTheme.amber,
            headerLabel: 'Capital Libre',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currencyFormat.format(capitalLibre),
                  style: RefugioTextStyles.moneyLarge.copyWith(
                    color: capitalLibre > 0 ? RefugioTheme.primary : RefugioTheme.amber,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Disponible para uso libre',
                  style: RefugioTextStyles.label,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Gastos Fijos Mensuales ──
          _buildFixedExpensesPreview(),
          const SizedBox(height: 16),

          // ── Fondos de Ahorro (preview) ──
          _buildSavingsSummary(),
          const SizedBox(height: 16),

          // ── Resumen de Pasivos ──
          RefugioCard(
            headerLabel: 'Resumen de Pasivos',
            child: Column(
              children: [
                _buildDebtSummaryRow(
                  'Compromisos Personales',
                  DatabaseService.getTotalDebtByCategory(DebtCategory.deudaDeHonor),
                  RefugioTheme.debtHonor,
                ),
                const SizedBox(height: 8),
                _buildDebtSummaryRow(
                  'Líneas Estratégicas',
                  DatabaseService.getTotalDebtByCategory(DebtCategory.lineaEstrategica),
                  RefugioTheme.debtLinea,
                ),
                const SizedBox(height: 8),
                _buildDebtSummaryRow(
                  'Pasivos Prioritarios',
                  DatabaseService.getTotalDebtByCategory(DebtCategory.basuraFinanciera),
                  RefugioTheme.debtBasura,
                ),
                const SizedBox(height: 8),
                _buildDebtSummaryRow(
                  'En Pausa Estratégica',
                  DatabaseService.getTotalDebtByCategory(DebtCategory.laCongeladora),
                  RefugioTheme.debtCongeladora,
                ),
                Divider(color: RefugioTheme.cardBorder, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total de pasivos', style: RefugioTextStyles.label.copyWith(color: RefugioTheme.textPrimary)),
                    Text(
                      _currencyFormat.format(totalDebt),
                      style: RefugioTextStyles.body.copyWith(
                        color: RefugioTheme.salmon,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm', 'es').format(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panel de Control',
          style: RefugioTextStyles.heading.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            StatusIndicator(
              active: true,
              label: 'Conectado',
              activeColor: RefugioTheme.primary,
            ),
            const SizedBox(width: 16),
            Text(
              dateStr,
              style: RefugioTextStyles.label,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFundChecklist() {
    if (_fondoItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            const SizedBox(width: 10),
            Text('Cargando partidas…', style: RefugioTextStyles.label),
          ],
        ),
      );
    }

    final paidCount = _fondoItems.where((i) => i.isPaid).length;
    final total = _fondoItems.fold(0.0, (s, i) => s + i.targetAmount);
    final covered = _fondoItems.where((i) => i.isPaid).fold(0.0, (s, i) => s + i.targetAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$paidCount/${_fondoItems.length} cubiertas',
              style: RefugioTextStyles.label.copyWith(
                color: paidCount == _fondoItems.length
                    ? RefugioTheme.primary
                    : RefugioTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_currencyFormat.format(covered)} / ${_currencyFormat.format(total)}',
              style: RefugioTextStyles.label.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._fondoItems.map((item) => _buildFondoItemTile(item)),
      ],
    );
  }

  Widget _buildFondoItemTile(FondoItem item) {
    return GestureDetector(
      onTap: () async {
        await DatabaseService.toggleFondoItem(item.id);
        await _loadFondoItems();
      },
      onLongPress: () => _showEditAmountDialog(item),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: item.isPaid
              ? RefugioTheme.primary.withValues(alpha: 0.08)
              : RefugioTheme.background.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: item.isPaid ? RefugioTheme.primary.withValues(alpha: 0.3) : RefugioTheme.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                item.isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                key: ValueKey(item.isPaid),
                size: 20,
                color: item.isPaid ? RefugioTheme.primary : RefugioTheme.textMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: RefugioTextStyles.body.copyWith(
                  fontSize: 13,
                  color: item.isPaid ? RefugioTheme.textSecondary : RefugioTheme.textPrimary,
                  decoration: item.isPaid ? TextDecoration.lineThrough : null,
                  decorationColor: RefugioTheme.textMuted,
                ),
              ),
            ),
            Text(
              _currencyFormat.format(item.targetAmount),
              style: RefugioTextStyles.label.copyWith(
                fontSize: 12,
                color: item.isPaid ? RefugioTheme.primary : RefugioTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit_outlined,
              size: 12,
              color: RefugioTheme.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAmountDialog(FondoItem item) {
    final controller = TextEditingController(text: item.targetAmount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajustar monto: ${item.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto asignado',
            prefixText: '\$ ',
            suffixText: 'MXN',
          ),
          style: TextStyle(
            fontFamily: RefugioTheme.fontFamily,
            fontSize: 18,
            color: RefugioTheme.primary,
            fontWeight: FontWeight.w700,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: RefugioTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                await DatabaseService.updateFondoItemAmount(item.id, val);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                await _loadFondoItems();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsSummary() {
    final funds = DatabaseService.getAllSavingsFunds();
    final total = DatabaseService.getTotalSavingsBalance();

    return RefugioCard(
      borderColor: RefugioTheme.cobalt,
      headerLabel: 'Fondos de Ahorro',
      child: funds.isEmpty
          ? Row(
              children: [
                Icon(Icons.savings_outlined, color: RefugioTheme.cobalt, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Sin fondos activos. Créalos en la pestaña Fondos.',
                  style: RefugioTextStyles.label,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.savings_rounded, color: RefugioTheme.cobalt, size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currencyFormat.format(total),
                          style: RefugioTextStyles.moneyLarge.copyWith(
                            color: RefugioTheme.cobalt,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          '${funds.length} fondo${funds.length != 1 ? "s" : ""} activo${funds.length != 1 ? "s" : ""}',
                          style: RefugioTextStyles.label,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...funds.take(3).map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: f.type == 'inversion' ? RefugioTheme.cobalt : RefugioTheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(f.name, style: RefugioTextStyles.label.copyWith(fontSize: 12)),
                      ),
                      Text(
                        _currencyFormat.format(f.balance),
                        style: RefugioTextStyles.body.copyWith(
                          color: RefugioTheme.cobalt,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
                if (funds.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '+ ${funds.length - 3} más',
                      style: RefugioTextStyles.label.copyWith(fontSize: 11),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFixedExpensesPreview() {
    final fixedExpenses = DatabaseService.getAllFixedExpenses();
    if (fixedExpenses.isEmpty) {
      return SizedBox.shrink();
    }

    // Ordenar por dueDay
    final sorted = fixedExpenses.where((e) => e.isActive).toList()
      ..sort((a, b) => a.dueDay.compareTo(b.dueDay));

    if (sorted.isEmpty) {
      return SizedBox.shrink();
    }

    final currentMonth = DateTime.now();
    final monthKey = '${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}';

    return RefugioCard(
      borderColor: RefugioTheme.debtLinea,
      headerLabel: 'Gastos Fijos Mensuales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sorted.isEmpty)
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: RefugioTheme.textMuted, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Sin gastos fijos registrados',
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 13,
                    color: RefugioTheme.textMuted,
                  ),
                ),
              ],
            )
          else
            Column(
              children: sorted.map((expense) {
                // Verificar si fue pagado este mes
                final payments = DatabaseService.getAllFixedExpensePayments(expense.id);
                final paidThisMonth = payments
                    .where((p) {
                      final pKey = '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}';
                      return pKey == monthKey;
                    })
                    .isNotEmpty;

                final daysUntilDue = _daysUntilDue(expense.dueDay);
                final isOverdue = daysUntilDue < 0;
                final isPending = !paidThisMonth;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isPending && isOverdue
                          ? RefugioTheme.salmon.withValues(alpha: 0.08)
                          : isPending
                              ? RefugioTheme.debtLinea.withValues(alpha: 0.08)
                              : RefugioTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isPending && isOverdue
                            ? RefugioTheme.salmon.withValues(alpha: 0.4)
                            : isPending
                                ? RefugioTheme.debtLinea.withValues(alpha: 0.3)
                                : RefugioTheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${expense.dueDay}',
                              style: RefugioTextStyles.label.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isPending && isOverdue
                                    ? RefugioTheme.salmon
                                    : isPending
                                        ? RefugioTheme.debtLinea
                                        : RefugioTheme.primary,
                              ),
                            ),
                            Text(
                              'del mes',
                              style: RefugioTextStyles.label.copyWith(fontSize: 9),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.name,
                                style: RefugioTextStyles.body.copyWith(
                                  fontSize: 13,
                                  color: paidThisMonth ? RefugioTheme.textSecondary : RefugioTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isPending)
                                Text(
                                  daysUntilDue < 0
                                      ? 'Vencido hace ${-daysUntilDue} día${-daysUntilDue > 1 ? 's' : ''}'
                                      : 'Vence en $daysUntilDue día${daysUntilDue > 1 ? 's' : ''}',
                                  style: RefugioTextStyles.label.copyWith(
                                    fontSize: 11,
                                    color: isOverdue ? RefugioTheme.salmon : RefugioTheme.textMuted,
                                  ),
                                )
                              else
                                Text(
                                  'Pagado',
                                  style: RefugioTextStyles.label.copyWith(
                                    fontSize: 11,
                                    color: RefugioTheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currencyFormat.format(expense.amount),
                              style: RefugioTextStyles.body.copyWith(
                                fontSize: 12,
                                color: isPending && isOverdue
                                    ? RefugioTheme.salmon
                                    : isPending
                                        ? RefugioTheme.debtLinea
                                        : RefugioTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isPending)
                              Icon(
                                isOverdue
                                    ? Icons.warning_rounded
                                    : Icons.schedule_outlined,
                                size: 14,
                                color: isOverdue ? RefugioTheme.salmon : RefugioTheme.debtLinea,
                              )
                            else
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: RefugioTheme.primary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  int _daysUntilDue(int dueDay) {
    final now = DateTime.now();
    final currentDay = now.day;

    if (dueDay > currentDay) {
      return dueDay - currentDay;
    } else if (dueDay == currentDay) {
      return 0;
    } else {
      // Ya pasó este mes
      return -currentDay + dueDay; // Negativo indica vencido
    }
  }

  Widget _buildDebtSummaryRow(String label, double amount, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: RefugioTextStyles.label),
        ),
        Text(
          _currencyFormat.format(amount),
          style: RefugioTextStyles.body.copyWith(
            color: amount > 0 ? color : RefugioTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
