/// Constantes financieras de Refugio
class FinancialConstants {
  FinancialConstants._();

  /// Monto predeterminado del Fondo Intocable.
  /// El usuario puede cambiarlo desde Configuración.
  static const double fondoIntocableDefault = 2810.00;

  /// Partidas predeterminadas del Fondo Intocable (nombre → monto).
  /// Suma exacta: $2,810 MXN. El usuario puede ajustar nombres y montos desde Configuración.
  static const Map<String, double> fondoItemDefaults = {
    'Gasolina': 960.0,
    'Despensa': 950.0,
    'Deuda Mamá': 500.0,
    'Mascotas (6)': 400.0,
  };

  /// Umbral de interés para alerta (deuda de alto costo)
  static const double interestAlertThreshold = 100.0; // %

  /// Moneda
  static const String currency = 'MXN';
  static const String currencySymbol = '\$';
}
