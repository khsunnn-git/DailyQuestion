// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_record_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAnswerRecordEntityCollection on Isar {
  IsarCollection<AnswerRecordEntity> get answerRecordEntitys =>
      this.collection();
}

const AnswerRecordEntitySchema = CollectionSchema(
  name: r'AnswerRecordEntity',
  id: 4177939105023149291,
  properties: {
    r'answer': PropertySchema(
      id: 0,
      name: r'answer',
      type: IsarType.string,
    ),
    r'author': PropertySchema(
      id: 1,
      name: r'author',
      type: IsarType.string,
    ),
    r'bucketTag': PropertySchema(
      id: 2,
      name: r'bucketTag',
      type: IsarType.string,
    ),
    r'bucketTags': PropertySchema(
      id: 3,
      name: r'bucketTags',
      type: IsarType.stringList,
    ),
    r'createdAt': PropertySchema(
      id: 4,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'createdAtMillis': PropertySchema(
      id: 5,
      name: r'createdAtMillis',
      type: IsarType.long,
    ),
    r'isPublic': PropertySchema(
      id: 6,
      name: r'isPublic',
      type: IsarType.bool,
    ),
    r'questionDateKey': PropertySchema(
      id: 7,
      name: r'questionDateKey',
      type: IsarType.string,
    ),
    r'questionSlot': PropertySchema(
      id: 8,
      name: r'questionSlot',
      type: IsarType.long,
    ),
    r'questionText': PropertySchema(
      id: 9,
      name: r'questionText',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 10,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _answerRecordEntityEstimateSize,
  serialize: _answerRecordEntitySerialize,
  deserialize: _answerRecordEntityDeserialize,
  deserializeProp: _answerRecordEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'createdAtMillis': IndexSchema(
      id: -2739706252225730577,
      name: r'createdAtMillis',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'createdAtMillis',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _answerRecordEntityGetId,
  getLinks: _answerRecordEntityGetLinks,
  attach: _answerRecordEntityAttach,
  version: '3.1.0+1',
);

int _answerRecordEntityEstimateSize(
  AnswerRecordEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.answer.length * 3;
  bytesCount += 3 + object.author.length * 3;
  {
    final value = object.bucketTag;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.bucketTags.length * 3;
  {
    for (var i = 0; i < object.bucketTags.length; i++) {
      final value = object.bucketTags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.questionDateKey.length * 3;
  {
    final value = object.questionText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _answerRecordEntitySerialize(
  AnswerRecordEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.answer);
  writer.writeString(offsets[1], object.author);
  writer.writeString(offsets[2], object.bucketTag);
  writer.writeStringList(offsets[3], object.bucketTags);
  writer.writeDateTime(offsets[4], object.createdAt);
  writer.writeLong(offsets[5], object.createdAtMillis);
  writer.writeBool(offsets[6], object.isPublic);
  writer.writeString(offsets[7], object.questionDateKey);
  writer.writeLong(offsets[8], object.questionSlot);
  writer.writeString(offsets[9], object.questionText);
  writer.writeDateTime(offsets[10], object.updatedAt);
}

AnswerRecordEntity _answerRecordEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AnswerRecordEntity();
  object.answer = reader.readString(offsets[0]);
  object.author = reader.readString(offsets[1]);
  object.bucketTag = reader.readStringOrNull(offsets[2]);
  object.bucketTags = reader.readStringList(offsets[3]) ?? [];
  object.createdAt = reader.readDateTime(offsets[4]);
  object.createdAtMillis = reader.readLong(offsets[5]);
  object.id = id;
  object.isPublic = reader.readBool(offsets[6]);
  object.questionDateKey = reader.readString(offsets[7]);
  object.questionSlot = reader.readLong(offsets[8]);
  object.questionText = reader.readStringOrNull(offsets[9]);
  object.updatedAt = reader.readDateTime(offsets[10]);
  return object;
}

P _answerRecordEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _answerRecordEntityGetId(AnswerRecordEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _answerRecordEntityGetLinks(
    AnswerRecordEntity object) {
  return [];
}

void _answerRecordEntityAttach(
    IsarCollection<dynamic> col, Id id, AnswerRecordEntity object) {
  object.id = id;
}

extension AnswerRecordEntityByIndex on IsarCollection<AnswerRecordEntity> {
  Future<AnswerRecordEntity?> getByCreatedAtMillis(int createdAtMillis) {
    return getByIndex(r'createdAtMillis', [createdAtMillis]);
  }

  AnswerRecordEntity? getByCreatedAtMillisSync(int createdAtMillis) {
    return getByIndexSync(r'createdAtMillis', [createdAtMillis]);
  }

  Future<bool> deleteByCreatedAtMillis(int createdAtMillis) {
    return deleteByIndex(r'createdAtMillis', [createdAtMillis]);
  }

  bool deleteByCreatedAtMillisSync(int createdAtMillis) {
    return deleteByIndexSync(r'createdAtMillis', [createdAtMillis]);
  }

  Future<List<AnswerRecordEntity?>> getAllByCreatedAtMillis(
      List<int> createdAtMillisValues) {
    final values = createdAtMillisValues.map((e) => [e]).toList();
    return getAllByIndex(r'createdAtMillis', values);
  }

  List<AnswerRecordEntity?> getAllByCreatedAtMillisSync(
      List<int> createdAtMillisValues) {
    final values = createdAtMillisValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'createdAtMillis', values);
  }

  Future<int> deleteAllByCreatedAtMillis(List<int> createdAtMillisValues) {
    final values = createdAtMillisValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'createdAtMillis', values);
  }

  int deleteAllByCreatedAtMillisSync(List<int> createdAtMillisValues) {
    final values = createdAtMillisValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'createdAtMillis', values);
  }

  Future<Id> putByCreatedAtMillis(AnswerRecordEntity object) {
    return putByIndex(r'createdAtMillis', object);
  }

  Id putByCreatedAtMillisSync(AnswerRecordEntity object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'createdAtMillis', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCreatedAtMillis(List<AnswerRecordEntity> objects) {
    return putAllByIndex(r'createdAtMillis', objects);
  }

  List<Id> putAllByCreatedAtMillisSync(List<AnswerRecordEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'createdAtMillis', objects, saveLinks: saveLinks);
  }
}

extension AnswerRecordEntityQueryWhereSort
    on QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QWhere> {
  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhere>
      anyCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAtMillis'),
      );
    });
  }
}

extension AnswerRecordEntityQueryWhere
    on QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QWhereClause> {
  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhereClause>
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

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhereClause>
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

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhereClause>
      createdAtMillisEqualTo(int createdAtMillis) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAtMillis',
        value: [createdAtMillis],
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhereClause>
      createdAtMillisNotEqualTo(int createdAtMillis) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAtMillis',
              lower: [],
              upper: [createdAtMillis],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAtMillis',
              lower: [createdAtMillis],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAtMillis',
              lower: [createdAtMillis],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAtMillis',
              lower: [],
              upper: [createdAtMillis],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhereClause>
      createdAtMillisGreaterThan(
    int createdAtMillis, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAtMillis',
        lower: [createdAtMillis],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhereClause>
      createdAtMillisLessThan(
    int createdAtMillis, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAtMillis',
        lower: [],
        upper: [createdAtMillis],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterWhereClause>
      createdAtMillisBetween(
    int lowerCreatedAtMillis,
    int upperCreatedAtMillis, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAtMillis',
        lower: [lowerCreatedAtMillis],
        includeLower: includeLower,
        upper: [upperCreatedAtMillis],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AnswerRecordEntityQueryFilter
    on QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QFilterCondition> {
  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      answerEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      answerGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      answerLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      answerBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'answer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      answerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      answerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      answerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'answer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      answerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'answer',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      answerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'answer',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      answerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'answer',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      authorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      authorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      authorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      authorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'author',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      authorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      authorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      authorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      authorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'author',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      authorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'author',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      authorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'author',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bucketTag',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bucketTag',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bucketTag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bucketTag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bucketTag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bucketTag',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bucketTag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bucketTag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bucketTag',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bucketTag',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bucketTag',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bucketTag',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bucketTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bucketTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bucketTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bucketTags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bucketTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bucketTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bucketTags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bucketTags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bucketTags',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bucketTags',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bucketTags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bucketTags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bucketTags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bucketTags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bucketTags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      bucketTagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bucketTags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
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

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
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

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
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

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      createdAtMillisEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      createdAtMillisGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      createdAtMillisLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      createdAtMillisBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAtMillis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
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

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
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

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
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

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      isPublicEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPublic',
        value: value,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionDateKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questionDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionDateKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'questionDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionDateKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'questionDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionDateKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'questionDateKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionDateKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'questionDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionDateKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'questionDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionDateKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'questionDateKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionDateKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'questionDateKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionDateKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questionDateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionDateKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'questionDateKey',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionSlotEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questionSlot',
        value: value,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionSlotGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'questionSlot',
        value: value,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionSlotLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'questionSlot',
        value: value,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionSlotBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'questionSlot',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'questionText',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'questionText',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questionText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'questionText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'questionText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'questionText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'questionText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'questionText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'questionText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'questionText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'questionText',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      questionTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'questionText',
        value: '',
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
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

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
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

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterFilterCondition>
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

extension AnswerRecordEntityQueryObject
    on QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QFilterCondition> {}

extension AnswerRecordEntityQueryLinks
    on QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QFilterCondition> {}

extension AnswerRecordEntityQuerySortBy
    on QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QSortBy> {
  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByAnswer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answer', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByAnswerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answer', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByBucketTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bucketTag', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByBucketTagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bucketTag', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByCreatedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByIsPublic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPublic', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByIsPublicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPublic', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByQuestionDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionDateKey', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByQuestionDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionDateKey', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByQuestionSlot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionSlot', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByQuestionSlotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionSlot', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByQuestionText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionText', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByQuestionTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionText', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension AnswerRecordEntityQuerySortThenBy
    on QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QSortThenBy> {
  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByAnswer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answer', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByAnswerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'answer', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByBucketTag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bucketTag', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByBucketTagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bucketTag', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByCreatedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByIsPublic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPublic', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByIsPublicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPublic', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByQuestionDateKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionDateKey', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByQuestionDateKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionDateKey', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByQuestionSlot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionSlot', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByQuestionSlotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionSlot', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByQuestionText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionText', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByQuestionTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'questionText', Sort.desc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension AnswerRecordEntityQueryWhereDistinct
    on QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct> {
  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct>
      distinctByAnswer({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'answer', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct>
      distinctByAuthor({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'author', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct>
      distinctByBucketTag({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bucketTag', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct>
      distinctByBucketTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bucketTags');
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct>
      distinctByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMillis');
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct>
      distinctByIsPublic() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPublic');
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct>
      distinctByQuestionDateKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'questionDateKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct>
      distinctByQuestionSlot() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'questionSlot');
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct>
      distinctByQuestionText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'questionText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension AnswerRecordEntityQueryProperty
    on QueryBuilder<AnswerRecordEntity, AnswerRecordEntity, QQueryProperty> {
  QueryBuilder<AnswerRecordEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AnswerRecordEntity, String, QQueryOperations> answerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'answer');
    });
  }

  QueryBuilder<AnswerRecordEntity, String, QQueryOperations> authorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'author');
    });
  }

  QueryBuilder<AnswerRecordEntity, String?, QQueryOperations>
      bucketTagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bucketTag');
    });
  }

  QueryBuilder<AnswerRecordEntity, List<String>, QQueryOperations>
      bucketTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bucketTags');
    });
  }

  QueryBuilder<AnswerRecordEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<AnswerRecordEntity, int, QQueryOperations>
      createdAtMillisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMillis');
    });
  }

  QueryBuilder<AnswerRecordEntity, bool, QQueryOperations> isPublicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPublic');
    });
  }

  QueryBuilder<AnswerRecordEntity, String, QQueryOperations>
      questionDateKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'questionDateKey');
    });
  }

  QueryBuilder<AnswerRecordEntity, int, QQueryOperations>
      questionSlotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'questionSlot');
    });
  }

  QueryBuilder<AnswerRecordEntity, String?, QQueryOperations>
      questionTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'questionText');
    });
  }

  QueryBuilder<AnswerRecordEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
