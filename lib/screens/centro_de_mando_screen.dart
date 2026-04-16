import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/refugio_theme.dart';
import '../widgets/tactical_widgets.dart';
import '../services/database_service.dart';
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

  List<FondoItem> _partidas = [];

  @override
  void initState() {
    super.initState();
    _cargarPartidas();
  }

  Future<void> _cargarPartidas() async {
    final items = await DatabaseService.getOrCreatePartidas();
    if (mounted) setState(() => _partidas = items);
  }

  @override
  Widget build(BuildContext context) {
    final saldoTotal            = DatabaseService.getSaldoTotal();
    final necesidadesCubiertas  = DatabaseService.isNecesidadesCubiertas();
    final necesidadesAsignadas  = DatabaseService.getNecesidadesAsignadas();
    final totalDisponible = DatabaseService.getTotalDisponible();
    final totalDeuda      = DatabaseService.getTotalDebtRemaining();
    final totalPartidas         = _partidas.fold(0.0, (s, i) => s + i.targetAmount);
    final needsPct        = DatabaseService.getNeedsPercent();
    final wantsPct        = DatabaseService.getWantsPercent();
    final savingsPct      = DatabaseService.getSavingsPercent();

    return RefreshIndicator(
      color: RefugioTheme.primary,
      backgroundColor: RefugioTheme.surface,
      onRefresh: () async {
        await _cargarPartidas();
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),

          // ── Saldo Total ──
          RefugioCard(
            borderColor: RefugioTheme.primary,
            headerLabel: 'Saldo Total ${DatabaseService.getBankName()}',
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

          // ── Necesidades del Hogar ──
          RefugioCard(
            borderColor: necesidadesCubiertas ? RefugioTheme.primary : RefugioTheme.salmon,
            headerLabel: 'Necesidades del Hogar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      necesidadesCubiertas ? Icons.verified_rounded : Icons.info_outline_rounded,
                      color: necesidadesCubiertas ? RefugioTheme.primary : RefugioTheme.salmon,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            necesidadesCubiertas ? 'Cubiertas' : 'Pendiente',
                            style: necesidadesCubiertas
                                ? RefugioTextStyles.heading.copyWith(fontSize: 16, color: RefugioTheme.primary)
                                : RefugioTextStyles.alertSalmon.copyWith(fontSize: 16),
                          ),
                          Text(
                            '${_currencyFormat.format(necesidadesAsignadas)} / ${_currencyFormat.format(totalPartidas)}',
                            style: RefugioTextStyles.subtitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RefugioProgressBar(
                  progress: totalPartidas > 0
                      ? (necesidadesAsignadas / totalPartidas).clamp(0.0, 1.0)
                      : (necesidadesAsignadas > 0 ? 1.0 : 0.0),
                  color: necesidadesCubiertas ? RefugioTheme.primary : RefugioTheme.salmon,
                  label: 'Cobertura',
                  height: 10,
                ),
                const SizedBox(height: 16),
                _buildFundChecklist(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Disponible ──
          RefugioCard(
            borderColor: totalDisponible > 0 ? RefugioTheme.primary : RefugioTheme.amber,
            headerLabel: 'Disponible',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currencyFormat.format(totalDisponible),
                  style: RefugioTextStyles.moneyLarge.copyWith(
                    color: totalDisponible > 0 ? RefugioTheme.primary : RefugioTheme.amber,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Puedes usar este dinero libremente',
                  style: RefugioTextStyles.label,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Distribución del ingreso (50/30/20) ──
          _buildBudgetBreakdown(needsPct, wantsPct, savingsPct),
          const SizedBox(height: 16),

          // ── Gastos Fijos Mensuales ──
          _buildFixedExpensesPreview(),
          const SizedBox(height: 16),

          // ── Fondos de Ahorro (preview) ──
          _buildSavingsSummary(),
          const SizedBox(height: 16),

          // ── Resumen de Deudas ──
          RefugioCard(
            headerLabel: 'Resumen de Deudas',
            child: Column(
              children: [
                _buildDebtSummaryRow(
                  'Familia y Amigos',
                  DatabaseService.getTotalDebtByCategory(DebtCategory.deudaDeHonor),
                  RefugioTheme.debtHonor,
                ),
                const SizedBox(height: 8),
                _buildDebtSummaryRow(
                  'Tarjetas y Créditos',
                  DatabaseService.getTotalDebtByCategory(DebtCategory.lineaEstrategica),
                  RefugioTheme.debtLinea,
                ),
                const SizedBox(height: 8),
                _buildDebtSummaryRow(
                  'Deudas Urgentes',
                  DatabaseService.getTotalDebtByCategory(DebtCategory.basuraFinanciera),
                  RefugioTheme.debtBasura,
                ),
                const SizedBox(height: 8),
                _buildDebtSummaryRow(
                  'En Pausa',
                  DatabaseService.getTotalDebtByCategory(DebtCategory.laCongeladora),
                  RefugioTheme.debtCongeladora,
                ),
                Divider(color: RefugioTheme.cardBorder, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total de deudas', style: RefugioTextStyles.label.copyWith(color: RefugioTheme.textPrimary)),
                    Text(
                      _currencyFormat.format(totalDeuda),
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
          'Inicio',
          style: RefugioTextStyles.heading.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            StatusIndicator(
              active: true,
              label: 'Activo',
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
    if (_partidas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Row(
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
            const SizedBox(height: 10),
            _buildAddItemButton(),
          ],
        ),
      );
    }

    final paidCount = _partidas.where((i) => i.isPaid).length;
    final total = _partidas.fold(0.0, (s, i) => s + i.targetAmount);
    final covered = _partidas.where((i) => i.isPaid).fold(0.0, (s, i) => s + i.targetAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$paidCount/${_partidas.length} cubiertas',
              style: RefugioTextStyles.label.copyWith(
                color: paidCount == _partidas.length
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
        ..._partidas.map((item) => _buildFondoItemTile(item)),
        const SizedBox(height: 6),
        _buildAddItemButton(),
      ],
    );
  }

  Widget _buildAddItemButton() {
    return GestureDetector(
      onTap: _showAddItemDialog,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: RefugioTheme.primary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded,
                size: 15, color: RefugioTheme.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              'Agregar partida',
              style: RefugioTextStyles.label.copyWith(
                color: RefugioTheme.primary.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFondoItemTile(FondoItem item) {
    return Dismissible(
      key: Key('fondo_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: RefugioTheme.salmon.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: RefugioTheme.salmon, size: 18),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar partida'),
            content: Text('¿Quitar "${item.name}" de la lista de necesidades esta semana?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar',
                    style: TextStyle(color: RefugioTheme.textMuted)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: RefugioTheme.salmonDim),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await DatabaseService.deletePartida(item.id);
        await _cargarPartidas();
      },
      child: GestureDetector(
        onTap: () async {
          await DatabaseService.togglePartida(item.id);
          await _cargarPartidas();
        },
        onLongPress: () => _showEditItemDialog(item),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: item.isPaid
                ? RefugioTheme.primary.withValues(alpha: 0.08)
                : RefugioTheme.background.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: item.isPaid
                  ? RefugioTheme.primary.withValues(alpha: 0.3)
                  : RefugioTheme.cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  item.isPaid
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
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
                    color: item.isPaid
                        ? RefugioTheme.textSecondary
                        : RefugioTheme.textPrimary,
                    decoration: item.isPaid ? TextDecoration.lineThrough : null,
                    decorationColor: RefugioTheme.textMuted,
                  ),
                ),
              ),
              Text(
                _currencyFormat.format(item.targetAmount),
                style: RefugioTextStyles.label.copyWith(
                  fontSize: 12,
                  color: item.isPaid
                      ? RefugioTheme.primary
                      : RefugioTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.more_vert_rounded,
                size: 14,
                color: RefugioTheme.textMuted.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditItemDialog(FondoItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final amountCtrl =
        TextEditingController(text: item.targetAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar partida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre'),
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 15,
                color: RefugioTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monto',
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
          ],
        ),
        actions: [
          // Eliminar al lado izquierdo
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Eliminar partida'),
                  content: Text('¿Eliminar "${item.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar',
                          style: TextStyle(color: RefugioTheme.textMuted)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: RefugioTheme.salmonDim),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await DatabaseService.deletePartida(item.id);
                await _cargarPartidas();
              }
            },
            icon: const Icon(Icons.delete_outline_rounded,
                size: 15, color: RefugioTheme.salmon),
            label: const Text('Eliminar',
                style: TextStyle(color: RefugioTheme.salmon, fontSize: 13)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: RefugioTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final val = double.tryParse(amountCtrl.text.trim());
              if (name.isEmpty || val == null || val <= 0) return;
              await DatabaseService.updatePartida(item.id,
                  name: name, amount: val);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _cargarPartidas();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva partida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Agua, Luz, Internet…',
              ),
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 15,
                color: RefugioTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monto',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: RefugioTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final val = double.tryParse(amountCtrl.text.trim());
              if (name.isEmpty || val == null || val <= 0) return;
              Navigator.pop(ctx);
              await DatabaseService.addPartida(
                  name: name, amount: val);
              await _cargarPartidas();
            },
            child: const Text('Agregar'),
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
    final sorted = DatabaseService.getAllFixedExpenses()
        .where((e) => e.isActive)
        .toList()
      ..sort((a, b) => a.dueDay.compareTo(b.dueDay));

    if (sorted.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentMonth = DateTime.now();
    final monthKey = '${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}';

    return RefugioCard(
      borderColor: RefugioTheme.debtLinea,
      headerLabel: 'Gastos Fijos Mensuales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildBudgetBreakdown(int needsPct, int wantsPct, int savingsPct) {
    final monthly = DatabaseService.getCurrentMonthSummary();
    final totalIncome = monthly.incomes;

    return RefugioCard(
      headerLabel: 'Distribución del Ingreso',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Así se divide tu dinero (${DatabaseService.getFrequencyLabel().toLowerCase()})',
            style: RefugioTextStyles.label,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildBudgetTile('Necesidades', needsPct, RefugioTheme.amber,
                  totalIncome > 0 ? totalIncome * needsPct / 100 : null),
              const SizedBox(width: 8),
              _buildBudgetTile('Gastos', wantsPct, RefugioTheme.primary,
                  totalIncome > 0 ? totalIncome * wantsPct / 100 : null),
              const SizedBox(width: 8),
              _buildBudgetTile('Ahorro/Deudas', savingsPct, RefugioTheme.cobalt,
                  totalIncome > 0 ? totalIncome * savingsPct / 100 : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTile(String label, int pct, Color color, double? amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$pct%',
              style: RefugioTextStyles.heading.copyWith(
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: RefugioTextStyles.label.copyWith(fontSize: 10)),
            if (amount != null) ...[
              const SizedBox(height: 4),
              Text(
                _currencyFormat.format(amount),
                style: RefugioTextStyles.label.copyWith(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
