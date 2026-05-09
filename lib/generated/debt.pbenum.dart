// This is a generated file - do not edit.
//
// Generated from debt.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ReceiptOrderBy extends $pb.ProtobufEnum {
  static const ReceiptOrderBy RECEIPT_ORDER_BY_UNSPECIFIED =
      ReceiptOrderBy._(0, _omitEnumNames ? '' : 'RECEIPT_ORDER_BY_UNSPECIFIED');
  static const ReceiptOrderBy RECEIPT_ORDER_BY_ID =
      ReceiptOrderBy._(1, _omitEnumNames ? '' : 'RECEIPT_ORDER_BY_ID');
  static const ReceiptOrderBy RECEIPT_ORDER_BY_COST_TOTAL =
      ReceiptOrderBy._(2, _omitEnumNames ? '' : 'RECEIPT_ORDER_BY_COST_TOTAL');
  static const ReceiptOrderBy RECEIPT_ORDER_BY_COST_FOR_USER = ReceiptOrderBy._(
      3, _omitEnumNames ? '' : 'RECEIPT_ORDER_BY_COST_FOR_USER');
  static const ReceiptOrderBy RECEIPT_ORDER_BY_DUE_DATE =
      ReceiptOrderBy._(4, _omitEnumNames ? '' : 'RECEIPT_ORDER_BY_DUE_DATE');
  static const ReceiptOrderBy RECEIPT_ORDER_BY_REMAINING_FOR_USER =
      ReceiptOrderBy._(
          5, _omitEnumNames ? '' : 'RECEIPT_ORDER_BY_REMAINING_FOR_USER');

  static const $core.List<ReceiptOrderBy> values = <ReceiptOrderBy>[
    RECEIPT_ORDER_BY_UNSPECIFIED,
    RECEIPT_ORDER_BY_ID,
    RECEIPT_ORDER_BY_COST_TOTAL,
    RECEIPT_ORDER_BY_COST_FOR_USER,
    RECEIPT_ORDER_BY_DUE_DATE,
    RECEIPT_ORDER_BY_REMAINING_FOR_USER,
  ];

  static final $core.List<ReceiptOrderBy?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static ReceiptOrderBy? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ReceiptOrderBy._(super.value, super.name);
}

class ReceiptOrderDirection extends $pb.ProtobufEnum {
  static const ReceiptOrderDirection RECEIPT_ORDER_DIRECTION_UNSPECIFIED =
      ReceiptOrderDirection._(
          0, _omitEnumNames ? '' : 'RECEIPT_ORDER_DIRECTION_UNSPECIFIED');
  static const ReceiptOrderDirection RECEIPT_ORDER_DIRECTION_ASC =
      ReceiptOrderDirection._(
          1, _omitEnumNames ? '' : 'RECEIPT_ORDER_DIRECTION_ASC');
  static const ReceiptOrderDirection RECEIPT_ORDER_DIRECTION_DESC =
      ReceiptOrderDirection._(
          2, _omitEnumNames ? '' : 'RECEIPT_ORDER_DIRECTION_DESC');

  static const $core.List<ReceiptOrderDirection> values =
      <ReceiptOrderDirection>[
    RECEIPT_ORDER_DIRECTION_UNSPECIFIED,
    RECEIPT_ORDER_DIRECTION_ASC,
    RECEIPT_ORDER_DIRECTION_DESC,
  ];

  static final $core.List<ReceiptOrderDirection?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ReceiptOrderDirection? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ReceiptOrderDirection._(super.value, super.name);
}

class ReceiptActorFilter extends $pb.ProtobufEnum {
  static const ReceiptActorFilter RECEIPT_ACTOR_FILTER_UNSPECIFIED =
      ReceiptActorFilter._(
          0, _omitEnumNames ? '' : 'RECEIPT_ACTOR_FILTER_UNSPECIFIED');
  static const ReceiptActorFilter
      RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP = ReceiptActorFilter._(
          1,
          _omitEnumNames
              ? ''
              : 'RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP');
  static const ReceiptActorFilter RECEIPT_ACTOR_FILTER_OWNER =
      ReceiptActorFilter._(
          2, _omitEnumNames ? '' : 'RECEIPT_ACTOR_FILTER_OWNER');
  static const ReceiptActorFilter RECEIPT_ACTOR_FILTER_RECIPIENT_GROUP =
      ReceiptActorFilter._(
          3, _omitEnumNames ? '' : 'RECEIPT_ACTOR_FILTER_RECIPIENT_GROUP');

  static const $core.List<ReceiptActorFilter> values = <ReceiptActorFilter>[
    RECEIPT_ACTOR_FILTER_UNSPECIFIED,
    RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP,
    RECEIPT_ACTOR_FILTER_OWNER,
    RECEIPT_ACTOR_FILTER_RECIPIENT_GROUP,
  ];

  static final $core.List<ReceiptActorFilter?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ReceiptActorFilter? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ReceiptActorFilter._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
