import 'package:hive/hive.dart';

class Income extends HiveObject {
  String id;
  double amount;
  String type; // 'nomina_base' | 'ingreso_extra'
  DateTime date;
  /// Porción asignada a Necesidades (50% del ingreso por defecto).
  double necesidades;
  /// Porción asignada a Gastos Personales + Ahorro (el resto del ingreso).
  double gastos;
  String? note;

  Income({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.necesidades,
    required this.gastos,
    this.note,
  });
}

class IncomeAdapter extends TypeAdapter<Income> {
  @override
  final int typeId = 0;

  @override
  Income read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Income(
      id: fields[0] as String,
      amount: fields[1] as double,
      type: fields[2] as String,
      date: fields[3] as DateTime,
      necesidades: fields[4] as double,   // field index 4 — no cambia en Hive
      gastos: fields[5] as double,         // field index 5 — no cambia en Hive
      note: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Income obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.amount);
    writer.writeByte(2);
    writer.write(obj.type);
    writer.writeByte(3);
    writer.write(obj.date);
    writer.writeByte(4);
    writer.write(obj.necesidades);
    writer.writeByte(5);
    writer.write(obj.gastos);
    writer.writeByte(6);
    writer.write(obj.note);
  }
}
