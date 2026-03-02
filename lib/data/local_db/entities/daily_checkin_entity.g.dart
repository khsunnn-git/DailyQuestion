// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_checkin_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDailyCheckinEntityCollection on Isar {
  IsarCollection<DailyCheckinEntity> get dailyCheckinEntitys =>
      this.collection();
}

const DailyCheckinEntitySchema = CollectionSchema(
  name: r'DailyCheckinEntity',
  id: -4618043869166873844,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dateKey': PropertySchema(
      id: 1,
      name: r'dateKey',
      type: IsarType.string,
    ),
    r'energyIndex': PropertySchema(
      id: 2,
      name: r'energyIndex',
      type: IsarType.long,
    ),
    r'moodIndex': PropertySchema(
      id: 3,
      name: r'moodIndex',
      type: IsarType.long,
    ),
    r'stressIndex': PropertySchema(
      id: 4,
      name: r'stressIndex',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _dailyCheckinEntityEstimateSize,
  serialize: _dailyCheckinEntitySerialize,
  deserialize: _dailyCheckinEntityDeserialize,
  deserializeProp: _dailyCheckinEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateKey': IndexSchema(
      id: 7975223786082927131,
      name: r'dateKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'dateKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _dailyCheckinEntityGetId,
  getLinks: _dailyCheckinEntityGetLinks,
  attach: _dailyCheckinEntityAttach,
  version: '3.1.0+1',
);

int _dailyCheckinEntityEstimateSize(
  DailyCheckinEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dateKey.length * 3;
  return bytesCount;
}

void _dailyCheckinEntitySerialize(
  DailyCheckinEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.dateKey);
  writer.writeLong(offsets[2], object.energyIndex);
  writer.writeLong(offsets[3], object.moodIndex);
  writer.writeLong(offsets[4], object.stressIndex);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

DailyCheckinEntity _dailyCheckinEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DailyCheckinEntity();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.dateKey = reader.readString(offsets[1]);
  object.energyIndex = reader.readLongOrNull(offsets[2]);
  object.id = id;
  object.moodIndex = reader.readLongOrNull(offsets[3]);
  object.stressIndex = reader.readLongOrNull(offsets[4]);
  object.updatedAt = reader.readDateTime(offsets[5]);
  return object;
}

P _dailyCheckinEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dailyCheckinEntityGetId(DailyCheckinEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dailyCheckinEntityGetLinks(
    DailyCheckinEntity object) {
  return [];
}

void _dailyCheckinEntityAttach(
    IsarCollection<dynamic> col, Id id, DailyCheckinEntity object) {
  object.id = id;
}

extension DailyCheckinEntityByIndex on IsarCollection<DailyCheckinEntity> {
  Future<DailyCheckinEntity?> getByDateKey(String dateKey) {
    return getByIndex(r'dateKey', [dateKey]);
  }

  DailyCheckinEntity? getByDateKeySync(String dateKey) {
    return getByIndexSync(r'dateKey', [dateKey]);
  }

  Future<bool> deleteByDateKey(String dateKey) {
    return deleteByIndex(r'dateKey', [dateKey]);
  }

  bool deleteByDateKeySync(String dateKey) {
    return deleteByIndexSync(r'dateKey', [dateKey]);
  }

  Future<List<DailyCheckinEntity?>> getAllByDateKey(
      List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'dateKey', values);
  }

  List<DailyCheckinEntity?> getAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'dateKey', values);
  }

  Future<int> deleteAllByDateKey(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'dateKey', values);
  }

  int deleteAllByDateKeySync(List<String> dateKeyValues) {
    final values = dateKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'dateKey', values);
  }

  Future<Id> putByDateKey(DailyCheckinEntity object) {
    return putByIndex(r'dateKey', object);
  }

  Id putByDateKeySync(DailyCheckinEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'dateKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDateKey(List<DailyCheckinEntity> objects) {
    return putAllByIndex(r'dateKey', objects);
  }

  List<Id> putAllByDateKeySync(List<DailyCheckinEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'dateKey', objects, saveLinks: saveLinks);
  }
}

extension DailyCheckinEntityQueryWhereSort
    on QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QWhere> {
  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DailyCheckinEntityQueryWhere
    on QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QWhereClause> {
  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterWhereClause>
      dateKeyEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dateKey',
        value: [dateKey],
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterWhereClause>
      dateKeyNotEqualTo(String dateKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [dateKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dateKey',
              lower: [],
              upper: [dateKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension DailyCheckinEntityQueryFilter
    on QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QFilterCondition> {
  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      dateKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      dateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      dateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      dateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      dateKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      dateKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      dateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      dateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      dateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      dateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      energyIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'energyIndex',
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      energyIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'energyIndex',
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      energyIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'energyIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      energyIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'energyIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      energyIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'energyIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      energyIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'energyIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      moodIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'moodIndex',
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      moodIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'moodIndex',
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      moodIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'moodIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      moodIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'moodIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      moodIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'moodIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      moodIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'moodIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      stressIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stressIndex',
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      stressIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stressIndex',
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      stressIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stressIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      stressIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stressIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      stressIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stressIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      stressIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stressIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DailyCheckinEntityQueryObject
    on QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QFilterCondition> {}

extension DailyCheckinEntityQueryLinks
    on QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QFilterCondition> {}

extension DailyCheckinEntityQuerySortBy
    on QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QSortBy> {
  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByEnergyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyIndex', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByEnergyIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyIndex', Sort.desc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByMoodIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodIndex', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByMoodIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodIndex', Sort.desc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByStressIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stressIndex', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByStressIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stressIndex', Sort.desc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DailyCheckinEntityQuerySortThenBy
    on QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QSortThenBy> {
  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateKey', Sort.desc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByEnergyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyIndex', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByEnergyIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'energyIndex', Sort.desc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByMoodIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodIndex', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByMoodIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodIndex', Sort.desc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByStressIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stressIndex', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByStressIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stressIndex', Sort.desc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DailyCheckinEntityQueryWhereDistinct
    on QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QDistinct> {
  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QDistinct>
      distinctByDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QDistinct>
      distinctByEnergyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'energyIndex');
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QDistinct>
      distinctByMoodIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'moodIndex');
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QDistinct>
      distinctByStressIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stressIndex');
    });
  }

  QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension DailyCheckinEntityQueryProperty
    on QueryBuilder<DailyCheckinEntity, DailyCheckinEntity, QQueryProperty> {
  QueryBuilder<DailyCheckinEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DailyCheckinEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<DailyCheckinEntity, String, QQueryOperations> dateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateKey');
    });
  }

  QueryBuilder<DailyCheckinEntity, int?, QQueryOperations>
      energyIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'energyIndex');
    });
  }

  QueryBuilder<DailyCheckinEntity, int?, QQueryOperations> moodIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'moodIndex');
    });
  }

  QueryBuilder<DailyCheckinEntity, int?, QQueryOperations>
      stressIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stressIndex');
    });
  }

  QueryBuilder<DailyCheckinEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
