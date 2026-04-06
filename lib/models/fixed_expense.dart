import 'package:hive/hive.dart';

class FixedExpense extends HiveObject {
  String id;
  String name;
  double amount;
  int dueDay; // 1..28 recomendado
  bool isActive;

  FixedExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    this.isActive = true,
  });
}

class FixedExpensePayment extends HiveObject {
  String id;
  String expenseId;
  double amount;
  DateTime date;
  String? note;

  FixedExpensePayment({
    required this.id,
    required this.expenseId,
    required this.amount,
    required this.date,
    this.note,
  });
}

class FixedExpenseAdapter extends TypeAdapter<FixedExpense> {
  @override
  final int typeId = 7;

  @override
  FixedExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return FixedExpense(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      dueDay: fields[3] as int,
      isActive: fields[4] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, FixedExpense obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
    writer.writeByte(2);
    writer.write(obj.amount);
    writer.writeByte(3);
    writer.write(obj.dueDay);
    writer.writeByte(4);
    writer.write(obj.isActive);
  }
}

class FixedExpensePaymentAdapter extends TypeAdapter<FixedExpensePayment> {
  @override
  final int typeId = 8;

  @override
  FixedExpensePayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return FixedExpensePayment(
      id: fields[0] as String,
      expenseId: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FixedExpensePayment obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.expenseId);
    writer.writeByte(2);
    writer.write(obj.amount);
    writer.writeByte(3);
    writer.write(obj.date);
    writer.writeByte(4);
    writer.write(obj.note);
  }
}
