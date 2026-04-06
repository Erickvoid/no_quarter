import 'package:hive/hive.dart';

/// Representa un gasto individual del Fondo Intocable en una semana dada.
/// Se crean automáticamente cada semana y el usuario los marca conforme los cubre.
class FondoItem extends HiveObject {
  String id;
  String name;
  double targetAmount;
  bool isPaid;
  DateTime weekStart;
  DateTime? paidAt;

  FondoItem({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.weekStart,
    this.isPaid = false,
    this.paidAt,
  });
}

class FondoItemAdapter extends TypeAdapter<FondoItem> {
  @override
  final int typeId = 4;

  @override
  FondoItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return FondoItem(
      id: fields[0] as String,
      name: fields[1] as String,
      targetAmount: fields[2] as double,
      weekStart: fields[3] as DateTime,
      isPaid: fields[4] as bool? ?? false,
      paidAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FondoItem obj) {
    writer.writeByte(6);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
    writer.writeByte(2);
    writer.write(obj.targetAmount);
    writer.writeByte(3);
    writer.write(obj.weekStart);
    writer.writeByte(4);
    writer.write(obj.isPaid);
    writer.writeByte(5);
    writer.write(obj.paidAt);
  }
}
