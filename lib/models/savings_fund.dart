import 'package:hive/hive.dart';

/// Fondo de ahorro o inversión al que el usuario aparta dinero de su Capital Libre.
class SavingsFund extends HiveObject {
  String id;
  String name;
  String type; // 'ahorro' | 'inversion'
  double balance;
  double targetAmount; // 0 = sin meta definida
  String? description;
  DateTime createdAt;
  bool isActive;

  SavingsFund({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.targetAmount = 0.0,
    this.description,
    required this.createdAt,
    this.isActive = true,
  });

  double get progressPercent =>
      targetAmount > 0 ? (balance / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get goalReached => targetAmount > 0 && balance >= targetAmount;
}

class SavingsFundAdapter extends TypeAdapter<SavingsFund> {
  @override
  final int typeId = 5;

  @override
  SavingsFund read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return SavingsFund(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      balance: fields[3] as double? ?? 0.0,
      targetAmount: fields[4] as double? ?? 0.0,
      description: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      isActive: fields[7] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsFund obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
    writer.writeByte(2);
    writer.write(obj.type);
    writer.writeByte(3);
    writer.write(obj.balance);
    writer.writeByte(4);
    writer.write(obj.targetAmount);
    writer.writeByte(5);
    writer.write(obj.description);
    writer.writeByte(6);
    writer.write(obj.createdAt);
    writer.writeByte(7);
    writer.write(obj.isActive);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Registro de un movimiento (depósito o retiro) en un SavingsFund.
class SavingsMovement extends HiveObject {
  String id;
  String fundId;
  double amount;
  bool isDeposit; // true = depositó desde Capital Libre; false = retiró
  String? note;
  DateTime date;

  SavingsMovement({
    required this.id,
    required this.fundId,
    required this.amount,
    required this.isDeposit,
    this.note,
    required this.date,
  });
}

class SavingsMovementAdapter extends TypeAdapter<SavingsMovement> {
  @override
  final int typeId = 6;

  @override
  SavingsMovement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return SavingsMovement(
      id: fields[0] as String,
      fundId: fields[1] as String,
      amount: fields[2] as double,
      isDeposit: fields[3] as bool,
      note: fields[4] as String?,
      date: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsMovement obj) {
    writer.writeByte(6);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.fundId);
    writer.writeByte(2);
    writer.write(obj.amount);
    writer.writeByte(3);
    writer.write(obj.isDeposit);
    writer.writeByte(4);
    writer.write(obj.note);
    writer.writeByte(5);
    writer.write(obj.date);
  }
}
