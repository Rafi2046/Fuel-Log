// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VehiclesTable extends Vehicles with TableInfo<$VehiclesTable, Vehicle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startOdoMeta = const VerificationMeta(
    'startOdo',
  );
  @override
  late final GeneratedColumn<double> startOdo = GeneratedColumn<double>(
    'start_odo',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capacityMeta = const VerificationMeta(
    'capacity',
  );
  @override
  late final GeneratedColumn<double> capacity = GeneratedColumn<double>(
    'capacity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fuelTypeMeta = const VerificationMeta(
    'fuelType',
  );
  @override
  late final GeneratedColumn<String> fuelType = GeneratedColumn<String>(
    'fuel_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isElectricMeta = const VerificationMeta(
    'isElectric',
  );
  @override
  late final GeneratedColumn<bool> isElectric = GeneratedColumn<bool>(
    'is_electric',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_electric" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    name,
    model,
    startOdo,
    capacity,
    fuelType,
    isElectric,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vehicle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('start_odo')) {
      context.handle(
        _startOdoMeta,
        startOdo.isAcceptableOrUnknown(data['start_odo']!, _startOdoMeta),
      );
    } else if (isInserting) {
      context.missing(_startOdoMeta);
    }
    if (data.containsKey('capacity')) {
      context.handle(
        _capacityMeta,
        capacity.isAcceptableOrUnknown(data['capacity']!, _capacityMeta),
      );
    } else if (isInserting) {
      context.missing(_capacityMeta);
    }
    if (data.containsKey('fuel_type')) {
      context.handle(
        _fuelTypeMeta,
        fuelType.isAcceptableOrUnknown(data['fuel_type']!, _fuelTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fuelTypeMeta);
    }
    if (data.containsKey('is_electric')) {
      context.handle(
        _isElectricMeta,
        isElectric.isAcceptableOrUnknown(data['is_electric']!, _isElectricMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vehicle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vehicle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      startOdo: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_odo'],
      )!,
      capacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}capacity'],
      )!,
      fuelType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fuel_type'],
      )!,
      isElectric: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_electric'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VehiclesTable createAlias(String alias) {
    return $VehiclesTable(attachedDatabase, alias);
  }
}

class Vehicle extends DataClass implements Insertable<Vehicle> {
  final int id;

  /// e.g. 'Car' or 'Bike'
  final String type;
  final String name;
  final String? model;
  final double startOdo;

  /// Tank liters or battery kWh (energy-agnostic).
  final double capacity;

  /// e.g. 'Petrol', 'Octane', 'Electric (EV)'
  final String fuelType;
  final bool isElectric;
  final DateTime createdAt;
  const Vehicle({
    required this.id,
    required this.type,
    required this.name,
    this.model,
    required this.startOdo,
    required this.capacity,
    required this.fuelType,
    required this.isElectric,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    map['start_odo'] = Variable<double>(startOdo);
    map['capacity'] = Variable<double>(capacity);
    map['fuel_type'] = Variable<String>(fuelType);
    map['is_electric'] = Variable<bool>(isElectric);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VehiclesCompanion toCompanion(bool nullToAbsent) {
    return VehiclesCompanion(
      id: Value(id),
      type: Value(type),
      name: Value(name),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      startOdo: Value(startOdo),
      capacity: Value(capacity),
      fuelType: Value(fuelType),
      isElectric: Value(isElectric),
      createdAt: Value(createdAt),
    );
  }

  factory Vehicle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vehicle(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      model: serializer.fromJson<String?>(json['model']),
      startOdo: serializer.fromJson<double>(json['startOdo']),
      capacity: serializer.fromJson<double>(json['capacity']),
      fuelType: serializer.fromJson<String>(json['fuelType']),
      isElectric: serializer.fromJson<bool>(json['isElectric']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'model': serializer.toJson<String?>(model),
      'startOdo': serializer.toJson<double>(startOdo),
      'capacity': serializer.toJson<double>(capacity),
      'fuelType': serializer.toJson<String>(fuelType),
      'isElectric': serializer.toJson<bool>(isElectric),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Vehicle copyWith({
    int? id,
    String? type,
    String? name,
    Value<String?> model = const Value.absent(),
    double? startOdo,
    double? capacity,
    String? fuelType,
    bool? isElectric,
    DateTime? createdAt,
  }) => Vehicle(
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
    model: model.present ? model.value : this.model,
    startOdo: startOdo ?? this.startOdo,
    capacity: capacity ?? this.capacity,
    fuelType: fuelType ?? this.fuelType,
    isElectric: isElectric ?? this.isElectric,
    createdAt: createdAt ?? this.createdAt,
  );
  Vehicle copyWithCompanion(VehiclesCompanion data) {
    return Vehicle(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      model: data.model.present ? data.model.value : this.model,
      startOdo: data.startOdo.present ? data.startOdo.value : this.startOdo,
      capacity: data.capacity.present ? data.capacity.value : this.capacity,
      fuelType: data.fuelType.present ? data.fuelType.value : this.fuelType,
      isElectric: data.isElectric.present
          ? data.isElectric.value
          : this.isElectric,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vehicle(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('model: $model, ')
          ..write('startOdo: $startOdo, ')
          ..write('capacity: $capacity, ')
          ..write('fuelType: $fuelType, ')
          ..write('isElectric: $isElectric, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    name,
    model,
    startOdo,
    capacity,
    fuelType,
    isElectric,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vehicle &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.model == this.model &&
          other.startOdo == this.startOdo &&
          other.capacity == this.capacity &&
          other.fuelType == this.fuelType &&
          other.isElectric == this.isElectric &&
          other.createdAt == this.createdAt);
}

class VehiclesCompanion extends UpdateCompanion<Vehicle> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> name;
  final Value<String?> model;
  final Value<double> startOdo;
  final Value<double> capacity;
  final Value<String> fuelType;
  final Value<bool> isElectric;
  final Value<DateTime> createdAt;
  const VehiclesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.model = const Value.absent(),
    this.startOdo = const Value.absent(),
    this.capacity = const Value.absent(),
    this.fuelType = const Value.absent(),
    this.isElectric = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  VehiclesCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String name,
    this.model = const Value.absent(),
    required double startOdo,
    required double capacity,
    required String fuelType,
    this.isElectric = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : type = Value(type),
       name = Value(name),
       startOdo = Value(startOdo),
       capacity = Value(capacity),
       fuelType = Value(fuelType);
  static Insertable<Vehicle> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? model,
    Expression<double>? startOdo,
    Expression<double>? capacity,
    Expression<String>? fuelType,
    Expression<bool>? isElectric,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (model != null) 'model': model,
      if (startOdo != null) 'start_odo': startOdo,
      if (capacity != null) 'capacity': capacity,
      if (fuelType != null) 'fuel_type': fuelType,
      if (isElectric != null) 'is_electric': isElectric,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  VehiclesCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? name,
    Value<String?>? model,
    Value<double>? startOdo,
    Value<double>? capacity,
    Value<String>? fuelType,
    Value<bool>? isElectric,
    Value<DateTime>? createdAt,
  }) {
    return VehiclesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      model: model ?? this.model,
      startOdo: startOdo ?? this.startOdo,
      capacity: capacity ?? this.capacity,
      fuelType: fuelType ?? this.fuelType,
      isElectric: isElectric ?? this.isElectric,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (startOdo.present) {
      map['start_odo'] = Variable<double>(startOdo.value);
    }
    if (capacity.present) {
      map['capacity'] = Variable<double>(capacity.value);
    }
    if (fuelType.present) {
      map['fuel_type'] = Variable<String>(fuelType.value);
    }
    if (isElectric.present) {
      map['is_electric'] = Variable<bool>(isElectric.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehiclesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('model: $model, ')
          ..write('startOdo: $startOdo, ')
          ..write('capacity: $capacity, ')
          ..write('fuelType: $fuelType, ')
          ..write('isElectric: $isElectric, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FuelLogsTable extends FuelLogs with TableInfo<$FuelLogsTable, FuelLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FuelLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vehicles (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _odometerMeta = const VerificationMeta(
    'odometer',
  );
  @override
  late final GeneratedColumn<double> odometer = GeneratedColumn<double>(
    'odometer',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFullTankMeta = const VerificationMeta(
    'isFullTank',
  );
  @override
  late final GeneratedColumn<bool> isFullTank = GeneratedColumn<bool>(
    'is_full_tank',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_full_tank" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    date,
    odometer,
    amount,
    cost,
    isFullTank,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fuel_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FuelLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('odometer')) {
      context.handle(
        _odometerMeta,
        odometer.isAcceptableOrUnknown(data['odometer']!, _odometerMeta),
      );
    } else if (isInserting) {
      context.missing(_odometerMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    } else if (isInserting) {
      context.missing(_costMeta);
    }
    if (data.containsKey('is_full_tank')) {
      context.handle(
        _isFullTankMeta,
        isFullTank.isAcceptableOrUnknown(
          data['is_full_tank']!,
          _isFullTankMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FuelLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FuelLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      odometer: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}odometer'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost'],
      )!,
      isFullTank: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_full_tank'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $FuelLogsTable createAlias(String alias) {
    return $FuelLogsTable(attachedDatabase, alias);
  }
}

class FuelLog extends DataClass implements Insertable<FuelLog> {
  final int id;
  final int vehicleId;
  final DateTime date;
  final double odometer;

  /// Liters or kWh depending on vehicle energy type.
  final double amount;
  final double cost;
  final bool isFullTank;
  final String? note;
  const FuelLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.amount,
    required this.cost,
    required this.isFullTank,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['vehicle_id'] = Variable<int>(vehicleId);
    map['date'] = Variable<DateTime>(date);
    map['odometer'] = Variable<double>(odometer);
    map['amount'] = Variable<double>(amount);
    map['cost'] = Variable<double>(cost);
    map['is_full_tank'] = Variable<bool>(isFullTank);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  FuelLogsCompanion toCompanion(bool nullToAbsent) {
    return FuelLogsCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      date: Value(date),
      odometer: Value(odometer),
      amount: Value(amount),
      cost: Value(cost),
      isFullTank: Value(isFullTank),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory FuelLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FuelLog(
      id: serializer.fromJson<int>(json['id']),
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      date: serializer.fromJson<DateTime>(json['date']),
      odometer: serializer.fromJson<double>(json['odometer']),
      amount: serializer.fromJson<double>(json['amount']),
      cost: serializer.fromJson<double>(json['cost']),
      isFullTank: serializer.fromJson<bool>(json['isFullTank']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'vehicleId': serializer.toJson<int>(vehicleId),
      'date': serializer.toJson<DateTime>(date),
      'odometer': serializer.toJson<double>(odometer),
      'amount': serializer.toJson<double>(amount),
      'cost': serializer.toJson<double>(cost),
      'isFullTank': serializer.toJson<bool>(isFullTank),
      'note': serializer.toJson<String?>(note),
    };
  }

  FuelLog copyWith({
    int? id,
    int? vehicleId,
    DateTime? date,
    double? odometer,
    double? amount,
    double? cost,
    bool? isFullTank,
    Value<String?> note = const Value.absent(),
  }) => FuelLog(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    date: date ?? this.date,
    odometer: odometer ?? this.odometer,
    amount: amount ?? this.amount,
    cost: cost ?? this.cost,
    isFullTank: isFullTank ?? this.isFullTank,
    note: note.present ? note.value : this.note,
  );
  FuelLog copyWithCompanion(FuelLogsCompanion data) {
    return FuelLog(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      date: data.date.present ? data.date.value : this.date,
      odometer: data.odometer.present ? data.odometer.value : this.odometer,
      amount: data.amount.present ? data.amount.value : this.amount,
      cost: data.cost.present ? data.cost.value : this.cost,
      isFullTank: data.isFullTank.present
          ? data.isFullTank.value
          : this.isFullTank,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FuelLog(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('odometer: $odometer, ')
          ..write('amount: $amount, ')
          ..write('cost: $cost, ')
          ..write('isFullTank: $isFullTank, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    date,
    odometer,
    amount,
    cost,
    isFullTank,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FuelLog &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.date == this.date &&
          other.odometer == this.odometer &&
          other.amount == this.amount &&
          other.cost == this.cost &&
          other.isFullTank == this.isFullTank &&
          other.note == this.note);
}

class FuelLogsCompanion extends UpdateCompanion<FuelLog> {
  final Value<int> id;
  final Value<int> vehicleId;
  final Value<DateTime> date;
  final Value<double> odometer;
  final Value<double> amount;
  final Value<double> cost;
  final Value<bool> isFullTank;
  final Value<String?> note;
  const FuelLogsCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.date = const Value.absent(),
    this.odometer = const Value.absent(),
    this.amount = const Value.absent(),
    this.cost = const Value.absent(),
    this.isFullTank = const Value.absent(),
    this.note = const Value.absent(),
  });
  FuelLogsCompanion.insert({
    this.id = const Value.absent(),
    required int vehicleId,
    required DateTime date,
    required double odometer,
    required double amount,
    required double cost,
    this.isFullTank = const Value.absent(),
    this.note = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       date = Value(date),
       odometer = Value(odometer),
       amount = Value(amount),
       cost = Value(cost);
  static Insertable<FuelLog> custom({
    Expression<int>? id,
    Expression<int>? vehicleId,
    Expression<DateTime>? date,
    Expression<double>? odometer,
    Expression<double>? amount,
    Expression<double>? cost,
    Expression<bool>? isFullTank,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (date != null) 'date': date,
      if (odometer != null) 'odometer': odometer,
      if (amount != null) 'amount': amount,
      if (cost != null) 'cost': cost,
      if (isFullTank != null) 'is_full_tank': isFullTank,
      if (note != null) 'note': note,
    });
  }

  FuelLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? vehicleId,
    Value<DateTime>? date,
    Value<double>? odometer,
    Value<double>? amount,
    Value<double>? cost,
    Value<bool>? isFullTank,
    Value<String?>? note,
  }) {
    return FuelLogsCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      odometer: odometer ?? this.odometer,
      amount: amount ?? this.amount,
      cost: cost ?? this.cost,
      isFullTank: isFullTank ?? this.isFullTank,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (odometer.present) {
      map['odometer'] = Variable<double>(odometer.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    if (isFullTank.present) {
      map['is_full_tank'] = Variable<bool>(isFullTank.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FuelLogsCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('odometer: $odometer, ')
          ..write('amount: $amount, ')
          ..write('cost: $cost, ')
          ..write('isFullTank: $isFullTank, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vehicles (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetOdometerMeta = const VerificationMeta(
    'targetOdometer',
  );
  @override
  late final GeneratedColumn<double> targetOdometer = GeneratedColumn<double>(
    'target_odometer',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _oilTypeMeta = const VerificationMeta(
    'oilType',
  );
  @override
  late final GeneratedColumn<String> oilType = GeneratedColumn<String>(
    'oil_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalKmMeta = const VerificationMeta(
    'intervalKm',
  );
  @override
  late final GeneratedColumn<double> intervalKm = GeneratedColumn<double>(
    'interval_km',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    title,
    targetDate,
    targetOdometer,
    isCompleted,
    oilType,
    intervalKm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('target_odometer')) {
      context.handle(
        _targetOdometerMeta,
        targetOdometer.isAcceptableOrUnknown(
          data['target_odometer']!,
          _targetOdometerMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('oil_type')) {
      context.handle(
        _oilTypeMeta,
        oilType.isAcceptableOrUnknown(data['oil_type']!, _oilTypeMeta),
      );
    }
    if (data.containsKey('interval_km')) {
      context.handle(
        _intervalKmMeta,
        intervalKm.isAcceptableOrUnknown(data['interval_km']!, _intervalKmMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      ),
      targetOdometer: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_odometer'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      oilType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oil_type'],
      ),
      intervalKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interval_km'],
      ),
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final int vehicleId;
  final String title;
  final DateTime? targetDate;
  final double? targetOdometer;
  final bool isCompleted;
  final String? oilType;
  final double? intervalKm;
  const Reminder({
    required this.id,
    required this.vehicleId,
    required this.title,
    this.targetDate,
    this.targetOdometer,
    required this.isCompleted,
    this.oilType,
    this.intervalKm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['vehicle_id'] = Variable<int>(vehicleId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    if (!nullToAbsent || targetOdometer != null) {
      map['target_odometer'] = Variable<double>(targetOdometer);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || oilType != null) {
      map['oil_type'] = Variable<String>(oilType);
    }
    if (!nullToAbsent || intervalKm != null) {
      map['interval_km'] = Variable<double>(intervalKm);
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      title: Value(title),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      targetOdometer: targetOdometer == null && nullToAbsent
          ? const Value.absent()
          : Value(targetOdometer),
      isCompleted: Value(isCompleted),
      oilType: oilType == null && nullToAbsent
          ? const Value.absent()
          : Value(oilType),
      intervalKm: intervalKm == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalKm),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<int>(json['id']),
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      title: serializer.fromJson<String>(json['title']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      targetOdometer: serializer.fromJson<double?>(json['targetOdometer']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      oilType: serializer.fromJson<String?>(json['oilType']),
      intervalKm: serializer.fromJson<double?>(json['intervalKm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'vehicleId': serializer.toJson<int>(vehicleId),
      'title': serializer.toJson<String>(title),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'targetOdometer': serializer.toJson<double?>(targetOdometer),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'oilType': serializer.toJson<String?>(oilType),
      'intervalKm': serializer.toJson<double?>(intervalKm),
    };
  }

  Reminder copyWith({
    int? id,
    int? vehicleId,
    String? title,
    Value<DateTime?> targetDate = const Value.absent(),
    Value<double?> targetOdometer = const Value.absent(),
    bool? isCompleted,
    Value<String?> oilType = const Value.absent(),
    Value<double?> intervalKm = const Value.absent(),
  }) => Reminder(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    title: title ?? this.title,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    targetOdometer: targetOdometer.present
        ? targetOdometer.value
        : this.targetOdometer,
    isCompleted: isCompleted ?? this.isCompleted,
    oilType: oilType.present ? oilType.value : this.oilType,
    intervalKm: intervalKm.present ? intervalKm.value : this.intervalKm,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      title: data.title.present ? data.title.value : this.title,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      targetOdometer: data.targetOdometer.present
          ? data.targetOdometer.value
          : this.targetOdometer,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      oilType: data.oilType.present ? data.oilType.value : this.oilType,
      intervalKm: data.intervalKm.present
          ? data.intervalKm.value
          : this.intervalKm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('targetOdometer: $targetOdometer, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('oilType: $oilType, ')
          ..write('intervalKm: $intervalKm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    title,
    targetDate,
    targetOdometer,
    isCompleted,
    oilType,
    intervalKm,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.title == this.title &&
          other.targetDate == this.targetDate &&
          other.targetOdometer == this.targetOdometer &&
          other.isCompleted == this.isCompleted &&
          other.oilType == this.oilType &&
          other.intervalKm == this.intervalKm);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<int> vehicleId;
  final Value<String> title;
  final Value<DateTime?> targetDate;
  final Value<double?> targetOdometer;
  final Value<bool> isCompleted;
  final Value<String?> oilType;
  final Value<double?> intervalKm;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.title = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.targetOdometer = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.oilType = const Value.absent(),
    this.intervalKm = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required int vehicleId,
    required String title,
    this.targetDate = const Value.absent(),
    this.targetOdometer = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.oilType = const Value.absent(),
    this.intervalKm = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       title = Value(title);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<int>? vehicleId,
    Expression<String>? title,
    Expression<DateTime>? targetDate,
    Expression<double>? targetOdometer,
    Expression<bool>? isCompleted,
    Expression<String>? oilType,
    Expression<double>? intervalKm,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (title != null) 'title': title,
      if (targetDate != null) 'target_date': targetDate,
      if (targetOdometer != null) 'target_odometer': targetOdometer,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (oilType != null) 'oil_type': oilType,
      if (intervalKm != null) 'interval_km': intervalKm,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? vehicleId,
    Value<String>? title,
    Value<DateTime?>? targetDate,
    Value<double?>? targetOdometer,
    Value<bool>? isCompleted,
    Value<String?>? oilType,
    Value<double?>? intervalKm,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      targetOdometer: targetOdometer ?? this.targetOdometer,
      isCompleted: isCompleted ?? this.isCompleted,
      oilType: oilType ?? this.oilType,
      intervalKm: intervalKm ?? this.intervalKm,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (targetOdometer.present) {
      map['target_odometer'] = Variable<double>(targetOdometer.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (oilType.present) {
      map['oil_type'] = Variable<String>(oilType.value);
    }
    if (intervalKm.present) {
      map['interval_km'] = Variable<double>(intervalKm.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('targetOdometer: $targetOdometer, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('oilType: $oilType, ')
          ..write('intervalKm: $intervalKm')
          ..write(')'))
        .toString();
  }
}

class $ServiceLogsTable extends ServiceLogs
    with TableInfo<$ServiceLogsTable, ServiceLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServiceLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vehicles (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
    'cost',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _odometerMeta = const VerificationMeta(
    'odometer',
  );
  @override
  late final GeneratedColumn<double> odometer = GeneratedColumn<double>(
    'odometer',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    date,
    category,
    title,
    cost,
    odometer,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'service_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServiceLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    } else if (isInserting) {
      context.missing(_costMeta);
    }
    if (data.containsKey('odometer')) {
      context.handle(
        _odometerMeta,
        odometer.isAcceptableOrUnknown(data['odometer']!, _odometerMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServiceLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServiceLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost'],
      )!,
      odometer: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}odometer'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $ServiceLogsTable createAlias(String alias) {
    return $ServiceLogsTable(attachedDatabase, alias);
  }
}

class ServiceLog extends DataClass implements Insertable<ServiceLog> {
  final int id;
  final int vehicleId;
  final DateTime date;
  final String category;
  final String title;
  final double cost;
  final double? odometer;
  final String? note;
  const ServiceLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.category,
    required this.title,
    required this.cost,
    this.odometer,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['vehicle_id'] = Variable<int>(vehicleId);
    map['date'] = Variable<DateTime>(date);
    map['category'] = Variable<String>(category);
    map['title'] = Variable<String>(title);
    map['cost'] = Variable<double>(cost);
    if (!nullToAbsent || odometer != null) {
      map['odometer'] = Variable<double>(odometer);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  ServiceLogsCompanion toCompanion(bool nullToAbsent) {
    return ServiceLogsCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      date: Value(date),
      category: Value(category),
      title: Value(title),
      cost: Value(cost),
      odometer: odometer == null && nullToAbsent
          ? const Value.absent()
          : Value(odometer),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory ServiceLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServiceLog(
      id: serializer.fromJson<int>(json['id']),
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      date: serializer.fromJson<DateTime>(json['date']),
      category: serializer.fromJson<String>(json['category']),
      title: serializer.fromJson<String>(json['title']),
      cost: serializer.fromJson<double>(json['cost']),
      odometer: serializer.fromJson<double?>(json['odometer']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'vehicleId': serializer.toJson<int>(vehicleId),
      'date': serializer.toJson<DateTime>(date),
      'category': serializer.toJson<String>(category),
      'title': serializer.toJson<String>(title),
      'cost': serializer.toJson<double>(cost),
      'odometer': serializer.toJson<double?>(odometer),
      'note': serializer.toJson<String?>(note),
    };
  }

  ServiceLog copyWith({
    int? id,
    int? vehicleId,
    DateTime? date,
    String? category,
    String? title,
    double? cost,
    Value<double?> odometer = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => ServiceLog(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    date: date ?? this.date,
    category: category ?? this.category,
    title: title ?? this.title,
    cost: cost ?? this.cost,
    odometer: odometer.present ? odometer.value : this.odometer,
    note: note.present ? note.value : this.note,
  );
  ServiceLog copyWithCompanion(ServiceLogsCompanion data) {
    return ServiceLog(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      cost: data.cost.present ? data.cost.value : this.cost,
      odometer: data.odometer.present ? data.odometer.value : this.odometer,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServiceLog(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('cost: $cost, ')
          ..write('odometer: $odometer, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, vehicleId, date, category, title, cost, odometer, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServiceLog &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.date == this.date &&
          other.category == this.category &&
          other.title == this.title &&
          other.cost == this.cost &&
          other.odometer == this.odometer &&
          other.note == this.note);
}

class ServiceLogsCompanion extends UpdateCompanion<ServiceLog> {
  final Value<int> id;
  final Value<int> vehicleId;
  final Value<DateTime> date;
  final Value<String> category;
  final Value<String> title;
  final Value<double> cost;
  final Value<double?> odometer;
  final Value<String?> note;
  const ServiceLogsCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.cost = const Value.absent(),
    this.odometer = const Value.absent(),
    this.note = const Value.absent(),
  });
  ServiceLogsCompanion.insert({
    this.id = const Value.absent(),
    required int vehicleId,
    required DateTime date,
    required String category,
    required String title,
    required double cost,
    this.odometer = const Value.absent(),
    this.note = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       date = Value(date),
       category = Value(category),
       title = Value(title),
       cost = Value(cost);
  static Insertable<ServiceLog> custom({
    Expression<int>? id,
    Expression<int>? vehicleId,
    Expression<DateTime>? date,
    Expression<String>? category,
    Expression<String>? title,
    Expression<double>? cost,
    Expression<double>? odometer,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (cost != null) 'cost': cost,
      if (odometer != null) 'odometer': odometer,
      if (note != null) 'note': note,
    });
  }

  ServiceLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? vehicleId,
    Value<DateTime>? date,
    Value<String>? category,
    Value<String>? title,
    Value<double>? cost,
    Value<double?>? odometer,
    Value<String?>? note,
  }) {
    return ServiceLogsCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      category: category ?? this.category,
      title: title ?? this.title,
      cost: cost ?? this.cost,
      odometer: odometer ?? this.odometer,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    if (odometer.present) {
      map['odometer'] = Variable<double>(odometer.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServiceLogsCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('cost: $cost, ')
          ..write('odometer: $odometer, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $TripLogsTable extends TripLogs with TableInfo<$TripLogsTable, TripLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<int> vehicleId = GeneratedColumn<int>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vehicles (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startOdoMeta = const VerificationMeta(
    'startOdo',
  );
  @override
  late final GeneratedColumn<double> startOdo = GeneratedColumn<double>(
    'start_odo',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endOdoMeta = const VerificationMeta('endOdo');
  @override
  late final GeneratedColumn<double> endOdo = GeneratedColumn<double>(
    'end_odo',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
    'distance_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costPerKmMeta = const VerificationMeta(
    'costPerKm',
  );
  @override
  late final GeneratedColumn<double> costPerKm = GeneratedColumn<double>(
    'cost_per_km',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCostMeta = const VerificationMeta(
    'totalCost',
  );
  @override
  late final GeneratedColumn<double> totalCost = GeneratedColumn<double>(
    'total_cost',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _privacyMeta = const VerificationMeta(
    'privacy',
  );
  @override
  late final GeneratedColumn<String> privacy = GeneratedColumn<String>(
    'privacy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeJsonMeta = const VerificationMeta(
    'routeJson',
  );
  @override
  late final GeneratedColumn<String> routeJson = GeneratedColumn<String>(
    'route_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vehicleId,
    title,
    origin,
    destination,
    startedAt,
    endedAt,
    startOdo,
    endOdo,
    distanceKm,
    durationSec,
    costPerKm,
    totalCost,
    source,
    privacy,
    note,
    routeJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trip_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('start_odo')) {
      context.handle(
        _startOdoMeta,
        startOdo.isAcceptableOrUnknown(data['start_odo']!, _startOdoMeta),
      );
    }
    if (data.containsKey('end_odo')) {
      context.handle(
        _endOdoMeta,
        endOdo.isAcceptableOrUnknown(data['end_odo']!, _endOdoMeta),
      );
    }
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceKmMeta);
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecMeta);
    }
    if (data.containsKey('cost_per_km')) {
      context.handle(
        _costPerKmMeta,
        costPerKm.isAcceptableOrUnknown(data['cost_per_km']!, _costPerKmMeta),
      );
    }
    if (data.containsKey('total_cost')) {
      context.handle(
        _totalCostMeta,
        totalCost.isAcceptableOrUnknown(data['total_cost']!, _totalCostMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('privacy')) {
      context.handle(
        _privacyMeta,
        privacy.isAcceptableOrUnknown(data['privacy']!, _privacyMeta),
      );
    } else if (isInserting) {
      context.missing(_privacyMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('route_json')) {
      context.handle(
        _routeJsonMeta,
        routeJson.isAcceptableOrUnknown(data['route_json']!, _routeJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TripLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      ),
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      startOdo: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}start_odo'],
      ),
      endOdo: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}end_odo'],
      ),
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_km'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      costPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_per_km'],
      ),
      totalCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_cost'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      privacy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}privacy'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      routeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_json'],
      ),
    );
  }

  @override
  $TripLogsTable createAlias(String alias) {
    return $TripLogsTable(attachedDatabase, alias);
  }
}

class TripLog extends DataClass implements Insertable<TripLog> {
  final int id;
  final int vehicleId;
  final String? title;
  final String? origin;
  final String? destination;
  final DateTime startedAt;
  final DateTime endedAt;
  final double? startOdo;
  final double? endOdo;
  final double distanceKm;
  final int durationSec;
  final double? costPerKm;
  final double? totalCost;
  final String source;
  final String privacy;
  final String? note;
  final String? routeJson;
  const TripLog({
    required this.id,
    required this.vehicleId,
    this.title,
    this.origin,
    this.destination,
    required this.startedAt,
    required this.endedAt,
    this.startOdo,
    this.endOdo,
    required this.distanceKm,
    required this.durationSec,
    this.costPerKm,
    this.totalCost,
    required this.source,
    required this.privacy,
    this.note,
    this.routeJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['vehicle_id'] = Variable<int>(vehicleId);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || origin != null) {
      map['origin'] = Variable<String>(origin);
    }
    if (!nullToAbsent || destination != null) {
      map['destination'] = Variable<String>(destination);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    if (!nullToAbsent || startOdo != null) {
      map['start_odo'] = Variable<double>(startOdo);
    }
    if (!nullToAbsent || endOdo != null) {
      map['end_odo'] = Variable<double>(endOdo);
    }
    map['distance_km'] = Variable<double>(distanceKm);
    map['duration_sec'] = Variable<int>(durationSec);
    if (!nullToAbsent || costPerKm != null) {
      map['cost_per_km'] = Variable<double>(costPerKm);
    }
    if (!nullToAbsent || totalCost != null) {
      map['total_cost'] = Variable<double>(totalCost);
    }
    map['source'] = Variable<String>(source);
    map['privacy'] = Variable<String>(privacy);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || routeJson != null) {
      map['route_json'] = Variable<String>(routeJson);
    }
    return map;
  }

  TripLogsCompanion toCompanion(bool nullToAbsent) {
    return TripLogsCompanion(
      id: Value(id),
      vehicleId: Value(vehicleId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      origin: origin == null && nullToAbsent
          ? const Value.absent()
          : Value(origin),
      destination: destination == null && nullToAbsent
          ? const Value.absent()
          : Value(destination),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      startOdo: startOdo == null && nullToAbsent
          ? const Value.absent()
          : Value(startOdo),
      endOdo: endOdo == null && nullToAbsent
          ? const Value.absent()
          : Value(endOdo),
      distanceKm: Value(distanceKm),
      durationSec: Value(durationSec),
      costPerKm: costPerKm == null && nullToAbsent
          ? const Value.absent()
          : Value(costPerKm),
      totalCost: totalCost == null && nullToAbsent
          ? const Value.absent()
          : Value(totalCost),
      source: Value(source),
      privacy: Value(privacy),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      routeJson: routeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(routeJson),
    );
  }

  factory TripLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripLog(
      id: serializer.fromJson<int>(json['id']),
      vehicleId: serializer.fromJson<int>(json['vehicleId']),
      title: serializer.fromJson<String?>(json['title']),
      origin: serializer.fromJson<String?>(json['origin']),
      destination: serializer.fromJson<String?>(json['destination']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      startOdo: serializer.fromJson<double?>(json['startOdo']),
      endOdo: serializer.fromJson<double?>(json['endOdo']),
      distanceKm: serializer.fromJson<double>(json['distanceKm']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      costPerKm: serializer.fromJson<double?>(json['costPerKm']),
      totalCost: serializer.fromJson<double?>(json['totalCost']),
      source: serializer.fromJson<String>(json['source']),
      privacy: serializer.fromJson<String>(json['privacy']),
      note: serializer.fromJson<String?>(json['note']),
      routeJson: serializer.fromJson<String?>(json['routeJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'vehicleId': serializer.toJson<int>(vehicleId),
      'title': serializer.toJson<String?>(title),
      'origin': serializer.toJson<String?>(origin),
      'destination': serializer.toJson<String?>(destination),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'startOdo': serializer.toJson<double?>(startOdo),
      'endOdo': serializer.toJson<double?>(endOdo),
      'distanceKm': serializer.toJson<double>(distanceKm),
      'durationSec': serializer.toJson<int>(durationSec),
      'costPerKm': serializer.toJson<double?>(costPerKm),
      'totalCost': serializer.toJson<double?>(totalCost),
      'source': serializer.toJson<String>(source),
      'privacy': serializer.toJson<String>(privacy),
      'note': serializer.toJson<String?>(note),
      'routeJson': serializer.toJson<String?>(routeJson),
    };
  }

  TripLog copyWith({
    int? id,
    int? vehicleId,
    Value<String?> title = const Value.absent(),
    Value<String?> origin = const Value.absent(),
    Value<String?> destination = const Value.absent(),
    DateTime? startedAt,
    DateTime? endedAt,
    Value<double?> startOdo = const Value.absent(),
    Value<double?> endOdo = const Value.absent(),
    double? distanceKm,
    int? durationSec,
    Value<double?> costPerKm = const Value.absent(),
    Value<double?> totalCost = const Value.absent(),
    String? source,
    String? privacy,
    Value<String?> note = const Value.absent(),
    Value<String?> routeJson = const Value.absent(),
  }) => TripLog(
    id: id ?? this.id,
    vehicleId: vehicleId ?? this.vehicleId,
    title: title.present ? title.value : this.title,
    origin: origin.present ? origin.value : this.origin,
    destination: destination.present ? destination.value : this.destination,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    startOdo: startOdo.present ? startOdo.value : this.startOdo,
    endOdo: endOdo.present ? endOdo.value : this.endOdo,
    distanceKm: distanceKm ?? this.distanceKm,
    durationSec: durationSec ?? this.durationSec,
    costPerKm: costPerKm.present ? costPerKm.value : this.costPerKm,
    totalCost: totalCost.present ? totalCost.value : this.totalCost,
    source: source ?? this.source,
    privacy: privacy ?? this.privacy,
    note: note.present ? note.value : this.note,
    routeJson: routeJson.present ? routeJson.value : this.routeJson,
  );
  TripLog copyWithCompanion(TripLogsCompanion data) {
    return TripLog(
      id: data.id.present ? data.id.value : this.id,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      title: data.title.present ? data.title.value : this.title,
      origin: data.origin.present ? data.origin.value : this.origin,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      startOdo: data.startOdo.present ? data.startOdo.value : this.startOdo,
      endOdo: data.endOdo.present ? data.endOdo.value : this.endOdo,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      costPerKm: data.costPerKm.present ? data.costPerKm.value : this.costPerKm,
      totalCost: data.totalCost.present ? data.totalCost.value : this.totalCost,
      source: data.source.present ? data.source.value : this.source,
      privacy: data.privacy.present ? data.privacy.value : this.privacy,
      note: data.note.present ? data.note.value : this.note,
      routeJson: data.routeJson.present ? data.routeJson.value : this.routeJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripLog(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('title: $title, ')
          ..write('origin: $origin, ')
          ..write('destination: $destination, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('startOdo: $startOdo, ')
          ..write('endOdo: $endOdo, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('durationSec: $durationSec, ')
          ..write('costPerKm: $costPerKm, ')
          ..write('totalCost: $totalCost, ')
          ..write('source: $source, ')
          ..write('privacy: $privacy, ')
          ..write('note: $note, ')
          ..write('routeJson: $routeJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vehicleId,
    title,
    origin,
    destination,
    startedAt,
    endedAt,
    startOdo,
    endOdo,
    distanceKm,
    durationSec,
    costPerKm,
    totalCost,
    source,
    privacy,
    note,
    routeJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripLog &&
          other.id == this.id &&
          other.vehicleId == this.vehicleId &&
          other.title == this.title &&
          other.origin == this.origin &&
          other.destination == this.destination &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.startOdo == this.startOdo &&
          other.endOdo == this.endOdo &&
          other.distanceKm == this.distanceKm &&
          other.durationSec == this.durationSec &&
          other.costPerKm == this.costPerKm &&
          other.totalCost == this.totalCost &&
          other.source == this.source &&
          other.privacy == this.privacy &&
          other.note == this.note &&
          other.routeJson == this.routeJson);
}

class TripLogsCompanion extends UpdateCompanion<TripLog> {
  final Value<int> id;
  final Value<int> vehicleId;
  final Value<String?> title;
  final Value<String?> origin;
  final Value<String?> destination;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<double?> startOdo;
  final Value<double?> endOdo;
  final Value<double> distanceKm;
  final Value<int> durationSec;
  final Value<double?> costPerKm;
  final Value<double?> totalCost;
  final Value<String> source;
  final Value<String> privacy;
  final Value<String?> note;
  final Value<String?> routeJson;
  const TripLogsCompanion({
    this.id = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.title = const Value.absent(),
    this.origin = const Value.absent(),
    this.destination = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.startOdo = const Value.absent(),
    this.endOdo = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.costPerKm = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.source = const Value.absent(),
    this.privacy = const Value.absent(),
    this.note = const Value.absent(),
    this.routeJson = const Value.absent(),
  });
  TripLogsCompanion.insert({
    this.id = const Value.absent(),
    required int vehicleId,
    this.title = const Value.absent(),
    this.origin = const Value.absent(),
    this.destination = const Value.absent(),
    required DateTime startedAt,
    required DateTime endedAt,
    this.startOdo = const Value.absent(),
    this.endOdo = const Value.absent(),
    required double distanceKm,
    required int durationSec,
    this.costPerKm = const Value.absent(),
    this.totalCost = const Value.absent(),
    required String source,
    required String privacy,
    this.note = const Value.absent(),
    this.routeJson = const Value.absent(),
  }) : vehicleId = Value(vehicleId),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       distanceKm = Value(distanceKm),
       durationSec = Value(durationSec),
       source = Value(source),
       privacy = Value(privacy);
  static Insertable<TripLog> custom({
    Expression<int>? id,
    Expression<int>? vehicleId,
    Expression<String>? title,
    Expression<String>? origin,
    Expression<String>? destination,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? startOdo,
    Expression<double>? endOdo,
    Expression<double>? distanceKm,
    Expression<int>? durationSec,
    Expression<double>? costPerKm,
    Expression<double>? totalCost,
    Expression<String>? source,
    Expression<String>? privacy,
    Expression<String>? note,
    Expression<String>? routeJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (title != null) 'title': title,
      if (origin != null) 'origin': origin,
      if (destination != null) 'destination': destination,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (startOdo != null) 'start_odo': startOdo,
      if (endOdo != null) 'end_odo': endOdo,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (durationSec != null) 'duration_sec': durationSec,
      if (costPerKm != null) 'cost_per_km': costPerKm,
      if (totalCost != null) 'total_cost': totalCost,
      if (source != null) 'source': source,
      if (privacy != null) 'privacy': privacy,
      if (note != null) 'note': note,
      if (routeJson != null) 'route_json': routeJson,
    });
  }

  TripLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? vehicleId,
    Value<String?>? title,
    Value<String?>? origin,
    Value<String?>? destination,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<double?>? startOdo,
    Value<double?>? endOdo,
    Value<double>? distanceKm,
    Value<int>? durationSec,
    Value<double?>? costPerKm,
    Value<double?>? totalCost,
    Value<String>? source,
    Value<String>? privacy,
    Value<String?>? note,
    Value<String?>? routeJson,
  }) {
    return TripLogsCompanion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      startOdo: startOdo ?? this.startOdo,
      endOdo: endOdo ?? this.endOdo,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSec: durationSec ?? this.durationSec,
      costPerKm: costPerKm ?? this.costPerKm,
      totalCost: totalCost ?? this.totalCost,
      source: source ?? this.source,
      privacy: privacy ?? this.privacy,
      note: note ?? this.note,
      routeJson: routeJson ?? this.routeJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<int>(vehicleId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (startOdo.present) {
      map['start_odo'] = Variable<double>(startOdo.value);
    }
    if (endOdo.present) {
      map['end_odo'] = Variable<double>(endOdo.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (costPerKm.present) {
      map['cost_per_km'] = Variable<double>(costPerKm.value);
    }
    if (totalCost.present) {
      map['total_cost'] = Variable<double>(totalCost.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (privacy.present) {
      map['privacy'] = Variable<String>(privacy.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (routeJson.present) {
      map['route_json'] = Variable<String>(routeJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripLogsCompanion(')
          ..write('id: $id, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('title: $title, ')
          ..write('origin: $origin, ')
          ..write('destination: $destination, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('startOdo: $startOdo, ')
          ..write('endOdo: $endOdo, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('durationSec: $durationSec, ')
          ..write('costPerKm: $costPerKm, ')
          ..write('totalCost: $totalCost, ')
          ..write('source: $source, ')
          ..write('privacy: $privacy, ')
          ..write('note: $note, ')
          ..write('routeJson: $routeJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VehiclesTable vehicles = $VehiclesTable(this);
  late final $FuelLogsTable fuelLogs = $FuelLogsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $ServiceLogsTable serviceLogs = $ServiceLogsTable(this);
  late final $TripLogsTable tripLogs = $TripLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vehicles,
    fuelLogs,
    reminders,
    serviceLogs,
    tripLogs,
  ];
}

typedef $$VehiclesTableCreateCompanionBuilder =
    VehiclesCompanion Function({
      Value<int> id,
      required String type,
      required String name,
      Value<String?> model,
      required double startOdo,
      required double capacity,
      required String fuelType,
      Value<bool> isElectric,
      Value<DateTime> createdAt,
    });
typedef $$VehiclesTableUpdateCompanionBuilder =
    VehiclesCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> name,
      Value<String?> model,
      Value<double> startOdo,
      Value<double> capacity,
      Value<String> fuelType,
      Value<bool> isElectric,
      Value<DateTime> createdAt,
    });

final class $$VehiclesTableReferences
    extends BaseReferences<_$AppDatabase, $VehiclesTable, Vehicle> {
  $$VehiclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FuelLogsTable, List<FuelLog>> _fuelLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.fuelLogs,
    aliasName: 'vehicles__id__fuel_logs__vehicle_id',
  );

  $$FuelLogsTableProcessedTableManager get fuelLogsRefs {
    final manager = $$FuelLogsTableTableManager(
      $_db,
      $_db.fuelLogs,
    ).filter((f) => f.vehicleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_fuelLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RemindersTable, List<Reminder>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: 'vehicles__id__reminders__vehicle_id',
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.vehicleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ServiceLogsTable, List<ServiceLog>>
  _serviceLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.serviceLogs,
    aliasName: 'vehicles__id__service_logs__vehicle_id',
  );

  $$ServiceLogsTableProcessedTableManager get serviceLogsRefs {
    final manager = $$ServiceLogsTableTableManager(
      $_db,
      $_db.serviceLogs,
    ).filter((f) => f.vehicleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_serviceLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TripLogsTable, List<TripLog>> _tripLogsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tripLogs,
    aliasName: 'vehicles__id__trip_logs__vehicle_id',
  );

  $$TripLogsTableProcessedTableManager get tripLogsRefs {
    final manager = $$TripLogsTableTableManager(
      $_db,
      $_db.tripLogs,
    ).filter((f) => f.vehicleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tripLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startOdo => $composableBuilder(
    column: $table.startOdo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isElectric => $composableBuilder(
    column: $table.isElectric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> fuelLogsRefs(
    Expression<bool> Function($$FuelLogsTableFilterComposer f) f,
  ) {
    final $$FuelLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelLogs,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelLogsTableFilterComposer(
            $db: $db,
            $table: $db.fuelLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> serviceLogsRefs(
    Expression<bool> Function($$ServiceLogsTableFilterComposer f) f,
  ) {
    final $$ServiceLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.serviceLogs,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServiceLogsTableFilterComposer(
            $db: $db,
            $table: $db.serviceLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tripLogsRefs(
    Expression<bool> Function($$TripLogsTableFilterComposer f) f,
  ) {
    final $$TripLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tripLogs,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripLogsTableFilterComposer(
            $db: $db,
            $table: $db.tripLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startOdo => $composableBuilder(
    column: $table.startOdo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isElectric => $composableBuilder(
    column: $table.isElectric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<double> get startOdo =>
      $composableBuilder(column: $table.startOdo, builder: (column) => column);

  GeneratedColumn<double> get capacity =>
      $composableBuilder(column: $table.capacity, builder: (column) => column);

  GeneratedColumn<String> get fuelType =>
      $composableBuilder(column: $table.fuelType, builder: (column) => column);

  GeneratedColumn<bool> get isElectric => $composableBuilder(
    column: $table.isElectric,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> fuelLogsRefs<T extends Object>(
    Expression<T> Function($$FuelLogsTableAnnotationComposer a) f,
  ) {
    final $$FuelLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fuelLogs,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.fuelLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> serviceLogsRefs<T extends Object>(
    Expression<T> Function($$ServiceLogsTableAnnotationComposer a) f,
  ) {
    final $$ServiceLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.serviceLogs,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServiceLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.serviceLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tripLogsRefs<T extends Object>(
    Expression<T> Function($$TripLogsTableAnnotationComposer a) f,
  ) {
    final $$TripLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tripLogs,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.tripLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VehiclesTable,
          Vehicle,
          $$VehiclesTableFilterComposer,
          $$VehiclesTableOrderingComposer,
          $$VehiclesTableAnnotationComposer,
          $$VehiclesTableCreateCompanionBuilder,
          $$VehiclesTableUpdateCompanionBuilder,
          (Vehicle, $$VehiclesTableReferences),
          Vehicle,
          PrefetchHooks Function({
            bool fuelLogsRefs,
            bool remindersRefs,
            bool serviceLogsRefs,
            bool tripLogsRefs,
          })
        > {
  $$VehiclesTableTableManager(_$AppDatabase db, $VehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<double> startOdo = const Value.absent(),
                Value<double> capacity = const Value.absent(),
                Value<String> fuelType = const Value.absent(),
                Value<bool> isElectric = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => VehiclesCompanion(
                id: id,
                type: type,
                name: name,
                model: model,
                startOdo: startOdo,
                capacity: capacity,
                fuelType: fuelType,
                isElectric: isElectric,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String name,
                Value<String?> model = const Value.absent(),
                required double startOdo,
                required double capacity,
                required String fuelType,
                Value<bool> isElectric = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => VehiclesCompanion.insert(
                id: id,
                type: type,
                name: name,
                model: model,
                startOdo: startOdo,
                capacity: capacity,
                fuelType: fuelType,
                isElectric: isElectric,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VehiclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                fuelLogsRefs = false,
                remindersRefs = false,
                serviceLogsRefs = false,
                tripLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (fuelLogsRefs) db.fuelLogs,
                    if (remindersRefs) db.reminders,
                    if (serviceLogsRefs) db.serviceLogs,
                    if (tripLogsRefs) db.tripLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (fuelLogsRefs)
                        await $_getPrefetchedData<
                          Vehicle,
                          $VehiclesTable,
                          FuelLog
                        >(
                          currentTable: table,
                          referencedTable: $$VehiclesTableReferences
                              ._fuelLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VehiclesTableReferences(
                                db,
                                table,
                                p0,
                              ).fuelLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.vehicleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (remindersRefs)
                        await $_getPrefetchedData<
                          Vehicle,
                          $VehiclesTable,
                          Reminder
                        >(
                          currentTable: table,
                          referencedTable: $$VehiclesTableReferences
                              ._remindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VehiclesTableReferences(
                                db,
                                table,
                                p0,
                              ).remindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.vehicleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (serviceLogsRefs)
                        await $_getPrefetchedData<
                          Vehicle,
                          $VehiclesTable,
                          ServiceLog
                        >(
                          currentTable: table,
                          referencedTable: $$VehiclesTableReferences
                              ._serviceLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VehiclesTableReferences(
                                db,
                                table,
                                p0,
                              ).serviceLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.vehicleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tripLogsRefs)
                        await $_getPrefetchedData<
                          Vehicle,
                          $VehiclesTable,
                          TripLog
                        >(
                          currentTable: table,
                          referencedTable: $$VehiclesTableReferences
                              ._tripLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VehiclesTableReferences(
                                db,
                                table,
                                p0,
                              ).tripLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.vehicleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VehiclesTable,
      Vehicle,
      $$VehiclesTableFilterComposer,
      $$VehiclesTableOrderingComposer,
      $$VehiclesTableAnnotationComposer,
      $$VehiclesTableCreateCompanionBuilder,
      $$VehiclesTableUpdateCompanionBuilder,
      (Vehicle, $$VehiclesTableReferences),
      Vehicle,
      PrefetchHooks Function({
        bool fuelLogsRefs,
        bool remindersRefs,
        bool serviceLogsRefs,
        bool tripLogsRefs,
      })
    >;
typedef $$FuelLogsTableCreateCompanionBuilder =
    FuelLogsCompanion Function({
      Value<int> id,
      required int vehicleId,
      required DateTime date,
      required double odometer,
      required double amount,
      required double cost,
      Value<bool> isFullTank,
      Value<String?> note,
    });
typedef $$FuelLogsTableUpdateCompanionBuilder =
    FuelLogsCompanion Function({
      Value<int> id,
      Value<int> vehicleId,
      Value<DateTime> date,
      Value<double> odometer,
      Value<double> amount,
      Value<double> cost,
      Value<bool> isFullTank,
      Value<String?> note,
    });

final class $$FuelLogsTableReferences
    extends BaseReferences<_$AppDatabase, $FuelLogsTable, FuelLog> {
  $$FuelLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VehiclesTable _vehicleIdTable(_$AppDatabase db) =>
      db.vehicles.createAlias('fuel_logs__vehicle_id__vehicles__id');

  $$VehiclesTableProcessedTableManager get vehicleId {
    final $_column = $_itemColumn<int>('vehicle_id')!;

    final manager = $$VehiclesTableTableManager(
      $_db,
      $_db.vehicles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vehicleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FuelLogsTableFilterComposer
    extends Composer<_$AppDatabase, $FuelLogsTable> {
  $$FuelLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFullTank => $composableBuilder(
    column: $table.isFullTank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$VehiclesTableFilterComposer get vehicleId {
    final $$VehiclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableFilterComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FuelLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $FuelLogsTable> {
  $$FuelLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFullTank => $composableBuilder(
    column: $table.isFullTank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$VehiclesTableOrderingComposer get vehicleId {
    final $$VehiclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableOrderingComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FuelLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FuelLogsTable> {
  $$FuelLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get odometer =>
      $composableBuilder(column: $table.odometer, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<bool> get isFullTank => $composableBuilder(
    column: $table.isFullTank,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$VehiclesTableAnnotationComposer get vehicleId {
    final $$VehiclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableAnnotationComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FuelLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FuelLogsTable,
          FuelLog,
          $$FuelLogsTableFilterComposer,
          $$FuelLogsTableOrderingComposer,
          $$FuelLogsTableAnnotationComposer,
          $$FuelLogsTableCreateCompanionBuilder,
          $$FuelLogsTableUpdateCompanionBuilder,
          (FuelLog, $$FuelLogsTableReferences),
          FuelLog,
          PrefetchHooks Function({bool vehicleId})
        > {
  $$FuelLogsTableTableManager(_$AppDatabase db, $FuelLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FuelLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FuelLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FuelLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> vehicleId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> odometer = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double> cost = const Value.absent(),
                Value<bool> isFullTank = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => FuelLogsCompanion(
                id: id,
                vehicleId: vehicleId,
                date: date,
                odometer: odometer,
                amount: amount,
                cost: cost,
                isFullTank: isFullTank,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int vehicleId,
                required DateTime date,
                required double odometer,
                required double amount,
                required double cost,
                Value<bool> isFullTank = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => FuelLogsCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                date: date,
                odometer: odometer,
                amount: amount,
                cost: cost,
                isFullTank: isFullTank,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FuelLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({vehicleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (vehicleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.vehicleId,
                                referencedTable: $$FuelLogsTableReferences
                                    ._vehicleIdTable(db),
                                referencedColumn: $$FuelLogsTableReferences
                                    ._vehicleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FuelLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FuelLogsTable,
      FuelLog,
      $$FuelLogsTableFilterComposer,
      $$FuelLogsTableOrderingComposer,
      $$FuelLogsTableAnnotationComposer,
      $$FuelLogsTableCreateCompanionBuilder,
      $$FuelLogsTableUpdateCompanionBuilder,
      (FuelLog, $$FuelLogsTableReferences),
      FuelLog,
      PrefetchHooks Function({bool vehicleId})
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      required int vehicleId,
      required String title,
      Value<DateTime?> targetDate,
      Value<double?> targetOdometer,
      Value<bool> isCompleted,
      Value<String?> oilType,
      Value<double?> intervalKm,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<int> vehicleId,
      Value<String> title,
      Value<DateTime?> targetDate,
      Value<double?> targetOdometer,
      Value<bool> isCompleted,
      Value<String?> oilType,
      Value<double?> intervalKm,
    });

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VehiclesTable _vehicleIdTable(_$AppDatabase db) =>
      db.vehicles.createAlias('reminders__vehicle_id__vehicles__id');

  $$VehiclesTableProcessedTableManager get vehicleId {
    final $_column = $_itemColumn<int>('vehicle_id')!;

    final manager = $$VehiclesTableTableManager(
      $_db,
      $_db.vehicles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vehicleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetOdometer => $composableBuilder(
    column: $table.targetOdometer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oilType => $composableBuilder(
    column: $table.oilType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get intervalKm => $composableBuilder(
    column: $table.intervalKm,
    builder: (column) => ColumnFilters(column),
  );

  $$VehiclesTableFilterComposer get vehicleId {
    final $$VehiclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableFilterComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetOdometer => $composableBuilder(
    column: $table.targetOdometer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oilType => $composableBuilder(
    column: $table.oilType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get intervalKm => $composableBuilder(
    column: $table.intervalKm,
    builder: (column) => ColumnOrderings(column),
  );

  $$VehiclesTableOrderingComposer get vehicleId {
    final $$VehiclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableOrderingComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetOdometer => $composableBuilder(
    column: $table.targetOdometer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get oilType =>
      $composableBuilder(column: $table.oilType, builder: (column) => column);

  GeneratedColumn<double> get intervalKm => $composableBuilder(
    column: $table.intervalKm,
    builder: (column) => column,
  );

  $$VehiclesTableAnnotationComposer get vehicleId {
    final $$VehiclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableAnnotationComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, $$RemindersTableReferences),
          Reminder,
          PrefetchHooks Function({bool vehicleId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> vehicleId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<double?> targetOdometer = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> oilType = const Value.absent(),
                Value<double?> intervalKm = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                vehicleId: vehicleId,
                title: title,
                targetDate: targetDate,
                targetOdometer: targetOdometer,
                isCompleted: isCompleted,
                oilType: oilType,
                intervalKm: intervalKm,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int vehicleId,
                required String title,
                Value<DateTime?> targetDate = const Value.absent(),
                Value<double?> targetOdometer = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> oilType = const Value.absent(),
                Value<double?> intervalKm = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                title: title,
                targetDate: targetDate,
                targetOdometer: targetOdometer,
                isCompleted: isCompleted,
                oilType: oilType,
                intervalKm: intervalKm,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({vehicleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (vehicleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.vehicleId,
                                referencedTable: $$RemindersTableReferences
                                    ._vehicleIdTable(db),
                                referencedColumn: $$RemindersTableReferences
                                    ._vehicleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, $$RemindersTableReferences),
      Reminder,
      PrefetchHooks Function({bool vehicleId})
    >;
typedef $$ServiceLogsTableCreateCompanionBuilder =
    ServiceLogsCompanion Function({
      Value<int> id,
      required int vehicleId,
      required DateTime date,
      required String category,
      required String title,
      required double cost,
      Value<double?> odometer,
      Value<String?> note,
    });
typedef $$ServiceLogsTableUpdateCompanionBuilder =
    ServiceLogsCompanion Function({
      Value<int> id,
      Value<int> vehicleId,
      Value<DateTime> date,
      Value<String> category,
      Value<String> title,
      Value<double> cost,
      Value<double?> odometer,
      Value<String?> note,
    });

final class $$ServiceLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ServiceLogsTable, ServiceLog> {
  $$ServiceLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VehiclesTable _vehicleIdTable(_$AppDatabase db) =>
      db.vehicles.createAlias('service_logs__vehicle_id__vehicles__id');

  $$VehiclesTableProcessedTableManager get vehicleId {
    final $_column = $_itemColumn<int>('vehicle_id')!;

    final manager = $$VehiclesTableTableManager(
      $_db,
      $_db.vehicles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vehicleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ServiceLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ServiceLogsTable> {
  $$ServiceLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$VehiclesTableFilterComposer get vehicleId {
    final $$VehiclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableFilterComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServiceLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ServiceLogsTable> {
  $$ServiceLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$VehiclesTableOrderingComposer get vehicleId {
    final $$VehiclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableOrderingComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServiceLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServiceLogsTable> {
  $$ServiceLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<double> get odometer =>
      $composableBuilder(column: $table.odometer, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$VehiclesTableAnnotationComposer get vehicleId {
    final $$VehiclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableAnnotationComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ServiceLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServiceLogsTable,
          ServiceLog,
          $$ServiceLogsTableFilterComposer,
          $$ServiceLogsTableOrderingComposer,
          $$ServiceLogsTableAnnotationComposer,
          $$ServiceLogsTableCreateCompanionBuilder,
          $$ServiceLogsTableUpdateCompanionBuilder,
          (ServiceLog, $$ServiceLogsTableReferences),
          ServiceLog,
          PrefetchHooks Function({bool vehicleId})
        > {
  $$ServiceLogsTableTableManager(_$AppDatabase db, $ServiceLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServiceLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServiceLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServiceLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> vehicleId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<double> cost = const Value.absent(),
                Value<double?> odometer = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => ServiceLogsCompanion(
                id: id,
                vehicleId: vehicleId,
                date: date,
                category: category,
                title: title,
                cost: cost,
                odometer: odometer,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int vehicleId,
                required DateTime date,
                required String category,
                required String title,
                required double cost,
                Value<double?> odometer = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => ServiceLogsCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                date: date,
                category: category,
                title: title,
                cost: cost,
                odometer: odometer,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ServiceLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({vehicleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (vehicleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.vehicleId,
                                referencedTable: $$ServiceLogsTableReferences
                                    ._vehicleIdTable(db),
                                referencedColumn: $$ServiceLogsTableReferences
                                    ._vehicleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ServiceLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServiceLogsTable,
      ServiceLog,
      $$ServiceLogsTableFilterComposer,
      $$ServiceLogsTableOrderingComposer,
      $$ServiceLogsTableAnnotationComposer,
      $$ServiceLogsTableCreateCompanionBuilder,
      $$ServiceLogsTableUpdateCompanionBuilder,
      (ServiceLog, $$ServiceLogsTableReferences),
      ServiceLog,
      PrefetchHooks Function({bool vehicleId})
    >;
typedef $$TripLogsTableCreateCompanionBuilder =
    TripLogsCompanion Function({
      Value<int> id,
      required int vehicleId,
      Value<String?> title,
      Value<String?> origin,
      Value<String?> destination,
      required DateTime startedAt,
      required DateTime endedAt,
      Value<double?> startOdo,
      Value<double?> endOdo,
      required double distanceKm,
      required int durationSec,
      Value<double?> costPerKm,
      Value<double?> totalCost,
      required String source,
      required String privacy,
      Value<String?> note,
      Value<String?> routeJson,
    });
typedef $$TripLogsTableUpdateCompanionBuilder =
    TripLogsCompanion Function({
      Value<int> id,
      Value<int> vehicleId,
      Value<String?> title,
      Value<String?> origin,
      Value<String?> destination,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<double?> startOdo,
      Value<double?> endOdo,
      Value<double> distanceKm,
      Value<int> durationSec,
      Value<double?> costPerKm,
      Value<double?> totalCost,
      Value<String> source,
      Value<String> privacy,
      Value<String?> note,
      Value<String?> routeJson,
    });

final class $$TripLogsTableReferences
    extends BaseReferences<_$AppDatabase, $TripLogsTable, TripLog> {
  $$TripLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VehiclesTable _vehicleIdTable(_$AppDatabase db) =>
      db.vehicles.createAlias('trip_logs__vehicle_id__vehicles__id');

  $$VehiclesTableProcessedTableManager get vehicleId {
    final $_column = $_itemColumn<int>('vehicle_id')!;

    final manager = $$VehiclesTableTableManager(
      $_db,
      $_db.vehicles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vehicleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TripLogsTableFilterComposer
    extends Composer<_$AppDatabase, $TripLogsTable> {
  $$TripLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get startOdo => $composableBuilder(
    column: $table.startOdo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endOdo => $composableBuilder(
    column: $table.endOdo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costPerKm => $composableBuilder(
    column: $table.costPerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privacy => $composableBuilder(
    column: $table.privacy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeJson => $composableBuilder(
    column: $table.routeJson,
    builder: (column) => ColumnFilters(column),
  );

  $$VehiclesTableFilterComposer get vehicleId {
    final $$VehiclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableFilterComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TripLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripLogsTable> {
  $$TripLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get startOdo => $composableBuilder(
    column: $table.startOdo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endOdo => $composableBuilder(
    column: $table.endOdo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costPerKm => $composableBuilder(
    column: $table.costPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCost => $composableBuilder(
    column: $table.totalCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privacy => $composableBuilder(
    column: $table.privacy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeJson => $composableBuilder(
    column: $table.routeJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$VehiclesTableOrderingComposer get vehicleId {
    final $$VehiclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableOrderingComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TripLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripLogsTable> {
  $$TripLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get startOdo =>
      $composableBuilder(column: $table.startOdo, builder: (column) => column);

  GeneratedColumn<double> get endOdo =>
      $composableBuilder(column: $table.endOdo, builder: (column) => column);

  GeneratedColumn<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costPerKm =>
      $composableBuilder(column: $table.costPerKm, builder: (column) => column);

  GeneratedColumn<double> get totalCost =>
      $composableBuilder(column: $table.totalCost, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get privacy =>
      $composableBuilder(column: $table.privacy, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get routeJson =>
      $composableBuilder(column: $table.routeJson, builder: (column) => column);

  $$VehiclesTableAnnotationComposer get vehicleId {
    final $$VehiclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableAnnotationComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TripLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripLogsTable,
          TripLog,
          $$TripLogsTableFilterComposer,
          $$TripLogsTableOrderingComposer,
          $$TripLogsTableAnnotationComposer,
          $$TripLogsTableCreateCompanionBuilder,
          $$TripLogsTableUpdateCompanionBuilder,
          (TripLog, $$TripLogsTableReferences),
          TripLog,
          PrefetchHooks Function({bool vehicleId})
        > {
  $$TripLogsTableTableManager(_$AppDatabase db, $TripLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> vehicleId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<double?> startOdo = const Value.absent(),
                Value<double?> endOdo = const Value.absent(),
                Value<double> distanceKm = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<double?> costPerKm = const Value.absent(),
                Value<double?> totalCost = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> privacy = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> routeJson = const Value.absent(),
              }) => TripLogsCompanion(
                id: id,
                vehicleId: vehicleId,
                title: title,
                origin: origin,
                destination: destination,
                startedAt: startedAt,
                endedAt: endedAt,
                startOdo: startOdo,
                endOdo: endOdo,
                distanceKm: distanceKm,
                durationSec: durationSec,
                costPerKm: costPerKm,
                totalCost: totalCost,
                source: source,
                privacy: privacy,
                note: note,
                routeJson: routeJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int vehicleId,
                Value<String?> title = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                required DateTime startedAt,
                required DateTime endedAt,
                Value<double?> startOdo = const Value.absent(),
                Value<double?> endOdo = const Value.absent(),
                required double distanceKm,
                required int durationSec,
                Value<double?> costPerKm = const Value.absent(),
                Value<double?> totalCost = const Value.absent(),
                required String source,
                required String privacy,
                Value<String?> note = const Value.absent(),
                Value<String?> routeJson = const Value.absent(),
              }) => TripLogsCompanion.insert(
                id: id,
                vehicleId: vehicleId,
                title: title,
                origin: origin,
                destination: destination,
                startedAt: startedAt,
                endedAt: endedAt,
                startOdo: startOdo,
                endOdo: endOdo,
                distanceKm: distanceKm,
                durationSec: durationSec,
                costPerKm: costPerKm,
                totalCost: totalCost,
                source: source,
                privacy: privacy,
                note: note,
                routeJson: routeJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TripLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({vehicleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (vehicleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.vehicleId,
                                referencedTable: $$TripLogsTableReferences
                                    ._vehicleIdTable(db),
                                referencedColumn: $$TripLogsTableReferences
                                    ._vehicleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TripLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripLogsTable,
      TripLog,
      $$TripLogsTableFilterComposer,
      $$TripLogsTableOrderingComposer,
      $$TripLogsTableAnnotationComposer,
      $$TripLogsTableCreateCompanionBuilder,
      $$TripLogsTableUpdateCompanionBuilder,
      (TripLog, $$TripLogsTableReferences),
      TripLog,
      PrefetchHooks Function({bool vehicleId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db, _db.vehicles);
  $$FuelLogsTableTableManager get fuelLogs =>
      $$FuelLogsTableTableManager(_db, _db.fuelLogs);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$ServiceLogsTableTableManager get serviceLogs =>
      $$ServiceLogsTableTableManager(_db, _db.serviceLogs);
  $$TripLogsTableTableManager get tripLogs =>
      $$TripLogsTableTableManager(_db, _db.tripLogs);
}
