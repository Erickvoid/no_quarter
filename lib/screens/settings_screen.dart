import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/refugio_theme.dart';
import '../widgets/tactical_widgets.dart';
import '../services/database_service.dart';
import '../models/constants.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsScreen({super.key, this.onSettingsChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _needsPctCtrl;
  late final TextEditingController _wantsPctCtrl;
  late String _frequency;
  late Map<String, double> _templates;
  bool _saving = false;
  bool _hasChanges = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _bankNameCtrl  = TextEditingController(text: DatabaseService.getBankName());
    _needsPctCtrl  = TextEditingController(text: DatabaseService.getNeedsPercent().toString());
    _wantsPctCtrl  = TextEditingController(text: DatabaseService.getWantsPercent().toString());
    _frequency     = DatabaseService.getFrequency();
    _templates     = Map.from(DatabaseService.getFondoItemTemplates());

    _bankNameCtrl.addListener(_markChanged);
    _needsPctCtrl.addListener(_markChanged);
    _wantsPctCtrl.addListener(_markChanged);
  }

  void _markChanged() => setState(() => _hasChanges = true);

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _needsPctCtrl.dispose();
    _wantsPctCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final bankName  = _bankNameCtrl.text.trim();
    final needsPct  = int.tryParse(_needsPctCtrl.text.trim());
    final wantsPct  = int.tryParse(_wantsPctCtrl.text.trim());

    if (bankName.isEmpty) {
      _showError('El nombre del banco no puede estar vacío.');
      return;
    }
    if (needsPct == null || needsPct < 10 || needsPct > 90) {
      _showError('El % de Necesidades debe estar entre 10 y 90.');
      return;
    }
    if (wantsPct == null || wantsPct < 0) {
      _showError('El % de Gastos Personales no puede ser negativo.');
      return;
    }
    if (needsPct + wantsPct > 95) {
      _showError('Necesidades + Gastos no pueden superar el 95%.');
      return;
    }
    if (_templates.isEmpty) {
      _showError('Agrega al menos una partida a la lista de necesidades.');
      return;
    }

    setState(() => _saving = true);
    await DatabaseService.setBankName(bankName);
    await DatabaseService.setNeedsPercent(needsPct);
    await DatabaseService.setWantsPercent(wantsPct);
    await DatabaseService.setFrequency(_frequency);
    await DatabaseService.setFondoItemTemplates(_templates);
    setState(() {
      _saving    = false;
      _hasChanges = false;
    });

    widget.onSettingsChanged?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configuración guardada'),
          backgroundColor: RefugioTheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: RefugioTheme.salmon,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer valores'),
        content: const Text(
          '¿Restablecer banco, monto, frecuencia y partidas a los valores originales?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: RefugioTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _bankNameCtrl.text  = 'BBVA';
                _needsPctCtrl.text  = '50';
                _wantsPctCtrl.text  = '30';
                _frequency          = 'weekly';
                _templates          = Map.from(FinancialConstants.fondoItemDefaults);
                _hasChanges         = true;
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: RefugioTheme.salmonDim),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
  }

  // ── Partidas del Fondo ──

  void _showAddOrEditPartidaDialog({String? existingName, double? existingAmount}) {
    final isEdit = existingName != null;
    final nameCtrl = TextEditingController(text: existingName ?? '');
    final amountCtrl = TextEditingController(
      text: existingAmount != null ? existingAmount.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Editar partida' : 'Nueva partida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Gasolina, Despensa, Internet…',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: !isEdit,
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                color: RefugioTheme.textPrimary,
              ),
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
              autofocus: isEdit,
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 18,
                color: RefugioTheme.amber,
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
            onPressed: () {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text.trim());
              if (name.isEmpty || amount == null || amount <= 0) return;

              // Prevent duplicate names (except when editing the same item)
              if (!isEdit && _templates.containsKey(name)) {
                Navigator.pop(ctx);
                _showError('Ya existe una partida con ese nombre.');
                return;
              }

              setState(() {
                if (isEdit && existingName != name) {
                  _templates.remove(existingName);
                }
                _templates[name] = amount;
                _hasChanges = true;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: RefugioTheme.amber),
            child: Text(isEdit ? 'Guardar' : 'Agregar'),
          ),
        ],
      ),
    );
  }

  void _removePartida(String name) {
    if (_templates.length <= 1) {
      _showError('Debe haber al menos una partida.');
      return;
    }
    setState(() {
      _templates.remove(name);
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final needsPct      = int.tryParse(_needsPctCtrl.text.trim()) ?? DatabaseService.getNeedsPercent();
    final wantsPct      = int.tryParse(_wantsPctCtrl.text.trim()) ?? DatabaseService.getWantsPercent();
    final savingsPct    = (100 - needsPct - wantsPct).clamp(0, 100);
    final templatesTotal = _templates.values.fold(0.0, (s, v) => s + v);

    return Scaffold(
      backgroundColor: RefugioTheme.background,
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: BackButton(
          onPressed: () {
            if (_hasChanges) {
              _showUnsavedDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            child: Text(
              'Restablecer',
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 13,
                color: RefugioTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Banco ──
          RefugioCard(
            headerLabel: 'Banco',
            borderColor: RefugioTheme.cobalt,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre de tu banco o cuenta principal',
                  style: RefugioTextStyles.label,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bankNameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ej: BBVA, Santander, Nubank…',
                    prefixIcon: const Icon(
                      Icons.account_balance_rounded,
                      color: RefugioTheme.cobalt,
                      size: 18,
                    ),
                    hintStyle: TextStyle(
                        color: RefugioTheme.textMuted,
                        fontFamily: RefugioTheme.fontFamily),
                  ),
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 16,
                    color: RefugioTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Distribución 50/30/20 ──
          RefugioCard(
            headerLabel: 'Distribución del Ingreso',
            borderColor: RefugioTheme.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Define cómo se divide automáticamente cada ingreso que registres.',
                  style: RefugioTextStyles.label,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Necesidades', style: RefugioTextStyles.label.copyWith(color: RefugioTheme.amber)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _needsPctCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              suffixText: '%',
                              hintText: '50',
                            ),
                            style: TextStyle(
                              fontFamily: RefugioTheme.fontFamily,
                              fontSize: 20,
                              color: RefugioTheme.amber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gastos Personales', style: RefugioTextStyles.label.copyWith(color: RefugioTheme.primary)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _wantsPctCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              suffixText: '%',
                              hintText: '30',
                            ),
                            style: TextStyle(
                              fontFamily: RefugioTheme.fontFamily,
                              fontSize: 20,
                              color: RefugioTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ahorro y Deudas', style: RefugioTextStyles.label.copyWith(color: RefugioTheme.cobalt)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              '$savingsPct%',
                              style: TextStyle(
                                fontFamily: RefugioTheme.fontFamily,
                                fontSize: 20,
                                color: RefugioTheme.cobalt,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RefugioTheme.amber.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RefugioTheme.amber.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: RefugioTheme.amber, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El % de Ahorro y Deudas se calcula automáticamente. Solo afecta ingresos futuros.',
                          style: RefugioTextStyles.label.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Lista de Necesidades ──
          RefugioCard(
            headerLabel: 'Lista de Necesidades del Hogar',
            borderColor: RefugioTheme.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estos son los gastos de necesidades de tu hogar. '
                  'Se usan como base al inicio de cada semana.',
                  style: RefugioTextStyles.label,
                ),
                const SizedBox(height: 14),

                // Lista de partidas
                ..._templates.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: RefugioTheme.amber.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: RefugioTheme.amber.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: RefugioTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _currencyFormat.format(entry.value),
                                style: RefugioTextStyles.label.copyWith(
                                  color: RefugioTheme.amber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 17, color: RefugioTheme.textMuted),
                          onPressed: () => _showAddOrEditPartidaDialog(
                            existingName: entry.key,
                            existingAmount: entry.value,
                          ),
                          tooltip: 'Editar',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline,
                              size: 17,
                              color: RefugioTheme.salmon.withValues(alpha: 0.7)),
                          onPressed: () => _removePartida(entry.key),
                          tooltip: 'Eliminar',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  );
                }),

                // Total partidas
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: RefugioTheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: RefugioTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total partidas',
                        style: RefugioTextStyles.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: RefugioTheme.primary,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(templatesTotal),
                        style: RefugioTextStyles.body.copyWith(
                          color: RefugioTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Botón agregar partida
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showAddOrEditPartidaDialog,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Agregar partida'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RefugioTheme.amber,
                      side: BorderSide(
                          color: RefugioTheme.amber.withValues(alpha: 0.5)),
                      textStyle: TextStyle(
                        fontFamily: RefugioTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Frecuencia de ingreso ──
          RefugioCard(
            headerLabel: 'Frecuencia de Ingreso',
            borderColor: RefugioTheme.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Define con qué frecuencia recibes tu ingreso principal. Afecta el cálculo del dinero disponible.',
                  style: RefugioTextStyles.label,
                ),
                const SizedBox(height: 14),
                _buildFrequencyOption(
                  value: 'weekly',
                  label: 'Semanal',
                  subtitle: 'Período: domingo a sábado (7 días)',
                  icon: Icons.view_week_outlined,
                ),
                const SizedBox(height: 8),
                _buildFrequencyOption(
                  value: 'biweekly',
                  label: 'Quincenal',
                  subtitle: 'Período: 14 días a partir del domingo anterior',
                  icon: Icons.date_range_outlined,
                ),
                const SizedBox(height: 8),
                _buildFrequencyOption(
                  value: 'monthly',
                  label: 'Mensual',
                  subtitle: 'Período: del 1 al último día del mes',
                  icon: Icons.calendar_month_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Guardar ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_hasChanges && !_saving) ? _save : null,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                _saving ? 'Guardando…' : 'Guardar cambios',
                style: const TextStyle(
                  fontFamily: RefugioTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasChanges
                    ? RefugioTheme.primary
                    : RefugioTheme.surfaceLight,
                foregroundColor:
                    _hasChanges ? Colors.white : RefugioTheme.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFrequencyOption({
    required String value,
    required String label,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _frequency == value;
    return GestureDetector(
      onTap: () => setState(() {
        _frequency = value;
        _hasChanges = true;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? RefugioTheme.primary.withValues(alpha: 0.1)
              : RefugioTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? RefugioTheme.primary.withValues(alpha: 0.5)
                : RefugioTheme.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color:
                    selected ? RefugioTheme.primary : RefugioTheme.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: RefugioTextStyles.body.copyWith(
                      color: selected
                          ? RefugioTheme.primary
                          : RefugioTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(subtitle,
                      style: RefugioTextStyles.label.copyWith(fontSize: 11)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: RefugioTheme.primary, size: 18),
          ],
        ),
      ),
    );
  }

  void _showUnsavedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text('¿Salir sin guardar los cambios?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Seguir editando',
                style: TextStyle(color: RefugioTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: RefugioTheme.salmonDim),
            child: const Text('Salir sin guardar'),
          ),
        ],
      ),
    );
  }
}
