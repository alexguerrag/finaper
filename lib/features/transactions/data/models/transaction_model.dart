import 'package:flutter/material.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    super.id,
    required super.description,
    required super.category,
    required super.amount,
    required super.isIncome,
    required super.date,
    required super.note,
    super.color, // Añadido para soportar personalización visual
  });

  // Factory para convertir datos de Base de Datos (Map) a Modelo
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id']?.toString(),
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      amount: (map['amount'] as num).toDouble(),
      isIncome: map['is_income'] == 1,
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
      // Recuperamos el color o asignamos uno por defecto usando el estándar moderno
      color: map['color_value'] != null
          ? Color(map['color_value']).withValues(alpha: 1.0)
          : Colors.blue.withValues(alpha: 1.0),
    );
  }

  // Método para convertir el Modelo a un Map para guardar en DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'category': category,
      'amount': amount,
      'is_income': isIncome ? 1 : 0,
      'date': date.toIso8601String(),
      'note': note,
      'color_value': color?.toARGB32() ?? Colors.blue.toARGB32(),
    };
  }

  // Mapper de Entidad a Modelo (Útil para la capa de Repositorio)
  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      description: entity.description,
      category: entity.category,
      amount: entity.amount,
      isIncome: entity.isIncome,
      date: entity.date,
      note: entity.note,
      color: entity.color?.withValues(alpha: 1.0),
    );
  }
}
