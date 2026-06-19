// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_buy_cache_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupBuyCacheModelAdapter extends TypeAdapter<GroupBuyCacheModel> {
  @override
  final int typeId = 20;

  @override
  GroupBuyCacheModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupBuyCacheModel(
      id: fields[0] as int,
      code: fields[1] as String,
      name: fields[2] as String,
      isPublic: fields[3] as bool,
      maxMembers: fields[4] as int,
      status: fields[5] as String,
      expiresAt: fields[6] as String?,
      createdAt: fields[7] as String,
      ownerId: fields[8] as int,
      ownerName: fields[9] as String,
      memberIds: (fields[10] as List).cast<String>(),
      memberNames: (fields[11] as List).cast<String>(),
      cartItemNames: (fields[12] as List).cast<String>(),
      cartItemQuantities: (fields[13] as List).cast<int>(),
      cartItemPrices: (fields[14] as List).cast<double>(),
      activityMessages: (fields[15] as List).cast<String>(),
      activityTimestamps: (fields[16] as List).cast<String>(),
      activityIcons: (fields[17] as List).cast<String>(),
      userId: fields[18] as int,
      userName: fields[19] as String,
      cachedAt: fields[20] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GroupBuyCacheModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.isPublic)
      ..writeByte(4)
      ..write(obj.maxMembers)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.expiresAt)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.ownerId)
      ..writeByte(9)
      ..write(obj.ownerName)
      ..writeByte(10)
      ..write(obj.memberIds)
      ..writeByte(11)
      ..write(obj.memberNames)
      ..writeByte(12)
      ..write(obj.cartItemNames)
      ..writeByte(13)
      ..write(obj.cartItemQuantities)
      ..writeByte(14)
      ..write(obj.cartItemPrices)
      ..writeByte(15)
      ..write(obj.activityMessages)
      ..writeByte(16)
      ..write(obj.activityTimestamps)
      ..writeByte(17)
      ..write(obj.activityIcons)
      ..writeByte(18)
      ..write(obj.userId)
      ..writeByte(19)
      ..write(obj.userName)
      ..writeByte(20)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupBuyCacheModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}