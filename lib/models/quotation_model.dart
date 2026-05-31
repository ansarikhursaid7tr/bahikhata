import 'package:cloud_firestore/cloud_firestore.dart';

class QuotationItem {
  final String description;
  final double amount;

  QuotationItem({
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
    };
  }

  factory QuotationItem.fromMap(Map<String, dynamic> map) {
    return QuotationItem(
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }
}

class QuotationSection {
  final String groupName;
  final String sectionName;
  final List<QuotationItem> items;

  QuotationSection({
    this.groupName = '',
    required this.sectionName,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'sectionName': sectionName,
      'items': items.map((x) => x.toMap()).toList(),
    };
  }

  factory QuotationSection.fromMap(Map<String, dynamic> map) {
    return QuotationSection(
      groupName: map['groupName'] ?? '',
      sectionName: map['sectionName'] ?? '',
      items: List<QuotationItem>.from((map['items'] ?? []).map((x) => QuotationItem.fromMap(x))),
    );
  }
  
  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.amount);
}

class Quotation {
  final String id;
  final String title;
  final String date;
  final String note;
  final List<QuotationSection> sections;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quotation({
    required this.id,
    required this.title,
    required this.date,
    this.note = '',
    required this.sections,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  double get grandTotal => sections.fold(0.0, (sum, sec) => sum + sec.totalAmount);

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'note': note,
      'sections': sections.map((x) => x.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Quotation.fromMap(Map<String, dynamic> map, String id) {
    return Quotation(
      id: id,
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      note: map['note'] ?? '',
      sections: List<QuotationSection>.from((map['sections'] ?? []).map((x) => QuotationSection.fromMap(x))),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
