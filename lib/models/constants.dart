/// Constantes financieras de Refugio
class FinancialConstants {
  FinancialConstants._();

  /// Fondo Intocable — Base vital que protege tu tranquilidad
  static const double bloqueDeTitanio = 2810.00;

  /// Partidas predeterminadas del Fondo Intocable.
  /// Suma exacta: $2,810 MXN. El usuario puede ajustar los montos.
  static const Map<String, double> fondoItemDefaults = {
    'Gasolina': 960.0,
    'Despensa': 950.0,
    'Deuda Mamá': 500.0,
    'Mascotas (6)': 400.0,
  };

  /// Desglose del Bloque de Titanio (legacy — usar fondoItemDefaults)
  static const double gasolina = 960.0;
  static const double despensa = 950.0;
  static const double apoyoMadre = 500.0;
  static const double fondoMascotas = 400.0;

  /// Nombres de las mascotas del Fondo Sagrado
  static const List<String> mascotas = [
    'Otilio',
    'Tadea',
    'Archivaldo',
    'Alfredito',
    'Chocolata',
    'Griselda',
  ];

  /// Umbral de interés para alerta roja (deuda usuraria)
  static const double interestAlertThreshold = 100.0; // %

  /// Día de depósito: Sábado
  static const int depositDay = DateTime.saturday; // 6

  /// Hora de depósito
  static const int depositHour = 1; // 1:00 AM

  /// Moneda
  static const String currency = 'MXN';
  static const String currencySymbol = '\$';
}
