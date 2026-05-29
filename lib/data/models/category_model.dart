import 'package:flutter/material.dart';
import 'package:pocket_karcha/data/models/expense_model.dart';

/// Maps to expense (You Gave) vs income (You Got) categories.
enum CategoryScope {
  gave,
  got;

  bool get isIncome => this == CategoryScope.got;

  static CategoryScope fromRecordType(ExpenseRecordType type) =>
      type == ExpenseRecordType.income ? CategoryScope.got : CategoryScope.gave;
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.labelEn,
    required this.labelUr,
    required this.iconCodePoint,
    required this.colorValue,
    required this.scope,
    this.isCustom = false,
  });

  final String id;
  final String labelEn;
  final String labelUr;
  final int iconCodePoint;
  final int colorValue;
  final CategoryScope scope;
  final bool isCustom;

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  String label(bool urdu) => urdu ? labelUr : labelEn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'labelEn': labelEn,
        'labelUr': labelUr,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'scope': scope.name,
        'isCustom': isCustom,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      labelEn: json['labelEn'] as String,
      labelUr: json['labelUr'] as String? ?? json['labelEn'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
      scope: CategoryScope.values.firstWhere(
        (s) => s.name == json['scope'],
        orElse: () => CategoryScope.gave,
      ),
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }

  CategoryModel copyWith({
    String? labelEn,
    String? labelUr,
    int? iconCodePoint,
    int? colorValue,
    bool? isCustom,
  }) {
    return CategoryModel(
      id: id,
      labelEn: labelEn ?? this.labelEn,
      labelUr: labelUr ?? this.labelUr,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      scope: scope,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
