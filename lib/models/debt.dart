import 'package:hive/hive.dart';

/// Categorías tácticas de deudas
enum DebtCategory {
  deudaDeHonor,       // Préstamos familiares/amigos - Prioridad Alta
  lineaEstrategica,   // Herramientas de supervivencia - Mantenimiento
  basuraFinanciera,   // Deudas usureras - Aniquilación Inmediata
  laCongeladora,      // Bancos tradicionales masivos - Impago táctico
}

class Debt extends HiveObject {
  String id;
  String name;
  String description;
  DebtCategory category;
  double totalAmount;
  double paidAmount;
  double monthlyPayment; // 0 for laCongeladora
  double interestRate;   // percentage
  DateTime createdAt;
  DateTime? lastPaymentDate;
  bool isActive;

  Debt({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.totalAmount,
    this.paidAmount = 0,
    this.monthlyPayment = 0,
    this.interestRate = 0,
    required this.createdAt,
    this.lastPaymentDate,
    this.isActive = true,
  });

  double get remainingAmount => totalAmount - paidAmount;
  double get progressPercent =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;
  bool get isUsurera => interestRate > 100; // Alert threshold
}

class DebtPayment extends HiveObject {
  String id;
  String debtId;
  double amount;
  DateTime date;
  String? note;

  DebtPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.note,
  });
}

// ── Hive Adapters ──

class DebtCategoryAdapter extends TypeAdapter<DebtCategory> {
  @override
  final int typeId = 1;

  @override
  DebtCategory read(BinaryReader reader) {
    return DebtCategory.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, DebtCategory obj) {
    writer.writeByte(obj.index);
  }
}

class DebtAdapter extends TypeAdapter<Debt> {
  @override
  final int typeId = 2;

  @override
  Debt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Debt(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as DebtCategory,
      totalAmount: fields[4] as double,
      paidAmount: fields[5] as double,
      monthlyPayment: fields[6] as double,
      interestRate: fields[7] as double,
      createdAt: fields[8] as DateTime,
      lastPaymentDate: fields[9] as DateTime?,
      isActive: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Debt obj) {
    writer.writeByte(11);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.name);
    writer.writeByte(2); writer.write(obj.description);
    writer.writeByte(3); writer.write(obj.category);
    writer.writeByte(4); writer.write(obj.totalAmount);
    writer.writeByte(5); writer.write(obj.paidAmount);
    writer.writeByte(6); writer.write(obj.monthlyPayment);
    writer.writeByte(7); writer.write(obj.interestRate);
    writer.writeByte(8); writer.write(obj.createdAt);
    writer.writeByte(9); writer.write(obj.lastPaymentDate);
    writer.writeByte(10); writer.write(obj.isActive);
  }
}

class DebtPaymentAdapter extends TypeAdapter<DebtPayment> {
  @override
  final int typeId = 3;

  @override
  DebtPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return DebtPayment(
      id: fields[0] as String,
      debtId: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DebtPayment obj) {
    writer.writeByte(5);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.debtId);
    writer.writeByte(2); writer.write(obj.amount);
    writer.writeByte(3); writer.write(obj.date);
    writer.writeByte(4); writer.write(obj.note);
  }
}
