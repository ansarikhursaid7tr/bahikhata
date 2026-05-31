import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/organization_model.dart';
import '../models/app_user_model.dart';
import '../models/staff_model.dart';
import '../models/item_type_model.dart';
import '../models/monthly_rate_model.dart';
import '../models/production_entry_model.dart';
import '../models/production_item_model.dart';
import '../models/money_entry_model.dart';
import '../models/audit_log_model.dart';
import '../models/quotation_model.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

/// Centralized Firestore service for all CRUD operations.
/// All queries are scoped by organizationId.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Organization ────────────────────────────────────────────

  Future<Organization?> getOrganization(String orgId) async {
    final doc = await _db.collection(Constants.organizationsCollection).doc(orgId).get();
    if (!doc.exists) return null;
    return Organization.fromFirestore(doc);
  }

  Future<void> updateOrganization(Organization org) async {
    await _db
        .collection(Constants.organizationsCollection)
        .doc(org.id)
        .update(org.toFirestore());
  }

  Future<String> createOrganization(Organization org) async {
    final docRef = _db.collection(Constants.organizationsCollection).doc();
    final newOrg = Organization(
      id: docRef.id,
      name: org.name,
      ownerId: org.ownerId,
      businessType: org.businessType,
      currency: org.currency,
      logoBase64: org.logoBase64,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newOrg.toFirestore());
    return docRef.id;
  }

  // ─── Users ───────────────────────────────────────────────────

  Future<AppUser?> getUserByUid(String orgId, String uid) async {
    final snapshot = await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('users')
        .doc(uid)
        .get();
    if (!snapshot.exists) return null;
    return AppUser.fromFirestore(snapshot);
  }

  /// Find which organization a user belongs to using a collection group query.
  Future<AppUser?> findUserAcrossOrganizations(String uid) async {
    final querySnapshot = await _db
        .collectionGroup('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
        
    if (querySnapshot.docs.isNotEmpty) {
      return AppUser.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  Future<void> createUserDocument(String orgId, AppUser user) async {
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore());
  }

  Future<void> deleteUserDocument(String orgId, String uid) async {
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('users')
        .doc(uid)
        .delete();
  }

  Stream<List<AppUser>> streamUsers(String orgId) {
    return _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('users')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }

  // ─── Staff ───────────────────────────────────────────────────

  Stream<List<Staff>> streamStaff(String orgId, {bool activeOnly = true}) {
    Query query = _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('staff');

    if (activeOnly) {
      query = query.where('active', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Staff.fromFirestore(doc)).toList());
  }

  Future<Staff?> getStaff(String orgId, String staffId) async {
    final doc = await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('staff')
        .doc(staffId)
        .get();
    if (!doc.exists) return null;
    return Staff.fromFirestore(doc);
  }

  Future<String> addStaff(String orgId, Staff staff) async {
    final docRef = _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('staff')
        .doc();
    final newStaff = Staff(
      id: docRef.id,
      name: staff.name,
      phone: staff.phone,
      staffType: staff.staffType,
      active: staff.active,
      userId: staff.userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newStaff.toFirestore());
    return docRef.id;
  }

  Future<void> updateStaff(String orgId, Staff staff) async {
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('staff')
        .doc(staff.id)
        .update(staff.toFirestore());
  }

  // ─── Item Types ──────────────────────────────────────────────

  Stream<List<ItemType>> streamItemTypes(String orgId,
      {bool activeOnly = true}) {
    Query query = _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('itemTypes');

    if (activeOnly) {
      query = query.where('active', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ItemType.fromFirestore(doc)).toList());
  }

  Future<String> addItemType(String orgId, ItemType itemType) async {
    final docRef = _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('itemTypes')
        .doc();
    final newItem = ItemType(
      id: docRef.id,
      name: itemType.name,
      category: itemType.category,
      active: itemType.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newItem.toFirestore());
    return docRef.id;
  }

  Future<void> updateItemType(String orgId, ItemType itemType) async {
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('itemTypes')
        .doc(itemType.id)
        .update(itemType.toFirestore());
  }

  // ─── Monthly Rates ──────────────────────────────────────────

  Stream<List<MonthlyRate>> streamRatesForMonth(String orgId, String month) {
    return _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('monthlyRates')
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MonthlyRate.fromFirestore(doc)).toList());
  }

  Future<List<MonthlyRate>> getRatesForMonth(
      String orgId, String month) async {
    final snapshot = await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('monthlyRates')
        .where('month', isEqualTo: month)
        .get();
    return snapshot.docs
        .map((doc) => MonthlyRate.fromFirestore(doc))
        .toList();
  }

  /// Returns a map of itemTypeId → rate for quick lookup.
  Future<Map<String, double>> getRateMap(String orgId, String month) async {
    final rates = await getRatesForMonth(orgId, month);
    return {for (var rate in rates) rate.itemTypeId: rate.rate};
  }

  Future<void> setRate(String orgId, MonthlyRate rate) async {
    // Use composite ID for uniqueness: one rate per item type per month.
    final docId = MonthlyRate.generateId(rate.month, rate.itemTypeId);
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('monthlyRates')
        .doc(docId)
        .set(rate.toFirestore(), SetOptions(merge: true));
  }

  Future<void> setRatesBatch(String orgId, List<MonthlyRate> rates) async {
    final batch = _db.batch();
    for (final rate in rates) {
      final docId = MonthlyRate.generateId(rate.month, rate.itemTypeId);
      final docRef = _db
          .collection(Constants.organizationsCollection)
          .doc(orgId)
          .collection('monthlyRates')
          .doc(docId);
      batch.set(docRef, rate.toFirestore(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ─── Production Entries ──────────────────────────────────────

  Stream<List<ProductionEntry>> streamProductionEntries(
    String orgId, {
    String? date,
    String? month,
    String? staffId,
  }) {
    Query query = _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('productionEntries');

    if (date != null) query = query.where('date', isEqualTo: date);
    if (month != null) query = query.where('month', isEqualTo: month);
    if (staffId != null) query = query.where('staffId', isEqualTo: staffId);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ProductionEntry.fromFirestore(doc)).toList();
      list.sort((a, b) => b.date.compareTo(a.date)); // Descending
      return list;
    });
  }

  Future<List<ProductionEntry>> getProductionEntries(
    String orgId, {
    String? date,
    String? month,
    String? staffId,
  }) async {
    Query query = _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('productionEntries');

    if (date != null) query = query.where('date', isEqualTo: date);
    if (month != null) query = query.where('month', isEqualTo: month);
    if (staffId != null) query = query.where('staffId', isEqualTo: staffId);

    final snapshot = await query.get();
    final list = snapshot.docs
        .map((doc) => ProductionEntry.fromFirestore(doc))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // Descending
    return list;
  }

  Future<String> addProductionEntry(
      String orgId, ProductionEntry entry) async {
    final docRef = _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('productionEntries')
        .doc();
    final data = entry.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> updateProductionEntry(
      String orgId, ProductionEntry entry) async {
    final data = entry.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['edited'] = true;
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('productionEntries')
        .doc(entry.id)
        .update(data);
  }

  Future<ProductionEntry?> getProductionEntryById(String orgId, String entryId) async {
    final doc = await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('productionEntries')
        .doc(entryId)
        .get();
    if (doc.exists) return ProductionEntry.fromFirestore(doc);
    return null;
  }

  Future<void> deleteProductionEntry(String orgId, String entryId) async {
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('productionEntries')
        .doc(entryId)
        .delete();
  }

  // ─── Money Entries ───────────────────────────────────────────

  Stream<List<MoneyEntry>> streamMoneyEntries(
    String orgId, {
    String? date,
    String? month,
    String? staffId,
  }) {
    Query query = _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('moneyEntries');

    if (date != null) query = query.where('date', isEqualTo: date);
    if (month != null) query = query.where('month', isEqualTo: month);
    if (staffId != null) query = query.where('staffId', isEqualTo: staffId);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => MoneyEntry.fromFirestore(doc)).toList();
      list.sort((a, b) => b.date.compareTo(a.date)); // Descending
      return list;
    });
  }

  Future<List<MoneyEntry>> getMoneyEntries(
    String orgId, {
    String? date,
    String? month,
    String? staffId,
  }) async {
    Query query = _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('moneyEntries');

    if (date != null) query = query.where('date', isEqualTo: date);
    if (month != null) query = query.where('month', isEqualTo: month);
    if (staffId != null) query = query.where('staffId', isEqualTo: staffId);

    final snapshot = await query.get();
    final list = snapshot.docs.map((doc) => MoneyEntry.fromFirestore(doc)).toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // Descending
    return list;
  }

  Future<String> addMoneyEntry(String orgId, MoneyEntry entry) async {
    final docRef = _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('moneyEntries')
        .doc();
    final data = entry.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
    return docRef.id;
  }

  Future<MoneyEntry?> getMoneyEntryById(String orgId, String entryId) async {
    final doc = await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('moneyEntries')
        .doc(entryId)
        .get();
    if (doc.exists) return MoneyEntry.fromFirestore(doc);
    return null;
  }

  Future<void> updateMoneyEntry(String orgId, MoneyEntry entry) async {
    final data = entry.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('moneyEntries')
        .doc(entry.id)
        .update(data);
  }

  Future<void> deleteMoneyEntry(String orgId, String entryId) async {
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('moneyEntries')
        .doc(entryId)
        .delete();
  }

  // ─── Audit Logs ──────────────────────────────────────────────

  Future<void> addAuditLog(String orgId, AuditLog log) async {
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('auditLogs')
        .doc()
        .set(log.toFirestore());
  }

  // ─── Seed Data ───────────────────────────────────────────────

  /// Seeds demo data. Called from settings or setup screen.
  Future<String> seedDemoData(String ownerId) async {
    final now = DateTime.now();

    // Create organization
    final orgRef = _db.collection(Constants.organizationsCollection).doc();
    final orgId = orgRef.id;
    await orgRef.set(Organization(
      id: orgId,
      name: 'BahiKhata Demo Shop',
      ownerId: ownerId,
      businessType: BusinessType.tailorShop,
      currency: '\$',
      createdAt: now,
      updatedAt: now,
    ).toFirestore());

    // Create owner user document
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('users')
        .doc(ownerId)
        .set(AppUser(
          id: ownerId,
          uid: ownerId,
          name: 'Owner',
          email: 'owner@bahikhata.local',
          username: 'owner',
          role: UserRole.owner,
          active: true,
          organizationId: orgId,
          createdAt: now,
          updatedAt: now,
        ).toFirestore());

    // Create staff
    final staffNames = ['Arjun', 'Sita', 'Ramesh'];
    final staffIds = <String, String>{};
    for (final name in staffNames) {
      final staffRef = _db
          .collection(Constants.organizationsCollection)
          .doc(orgId)
          .collection('staff')
          .doc();
      staffIds[name] = staffRef.id;
      await staffRef.set(Staff(
        id: staffRef.id,
        name: name,
        staffType: StaffType.tailor,
        active: true,
        createdAt: now,
        updatedAt: now,
      ).toFirestore());
    }

    // Create item types
    final itemNames = ['Coat', 'Pant', 'Shirt', 'Kurta', 'Blouse'];
    final itemIds = <String, String>{};
    for (final name in itemNames) {
      final itemRef = _db
          .collection(Constants.organizationsCollection)
          .doc(orgId)
          .collection('itemTypes')
          .doc();
      itemIds[name] = itemRef.id;
      await itemRef.set(ItemType(
        id: itemRef.id,
        name: name,
        category: 'Clothing',
        active: true,
        createdAt: now,
        updatedAt: now,
      ).toFirestore());
    }

    // May 2026 rates
    final rates = {'Coat': 20.0, 'Pant': 10.0, 'Shirt': 8.0, 'Kurta': 15.0, 'Blouse': 12.0};
    for (final entry in rates.entries) {
      final rateId = MonthlyRate.generateId('2026-05', itemIds[entry.key]!);
      await _db
          .collection(Constants.organizationsCollection)
          .doc(orgId)
          .collection('monthlyRates')
          .doc(rateId)
          .set(MonthlyRate(
            id: rateId,
            month: '2026-05',
            itemTypeId: itemIds[entry.key]!,
            itemTypeName: entry.key,
            rate: entry.value,
            createdBy: ownerId,
            createdAt: now,
            updatedAt: now,
          ).toFirestore());
    }

    // Sample production entry: Arjun, 2026-05-10
    final prodItems = [
      ProductionItem(
        itemTypeId: itemIds['Coat']!,
        itemTypeName: 'Coat',
        quantity: 2,
        rateSnapshot: 20.0,
      ),
      ProductionItem(
        itemTypeId: itemIds['Pant']!,
        itemTypeName: 'Pant',
        quantity: 1,
        rateSnapshot: 10.0,
      ),
      ProductionItem(
        itemTypeId: itemIds['Shirt']!,
        itemTypeName: 'Shirt',
        quantity: 3,
        rateSnapshot: 8.0,
      ),
    ];
    await addProductionEntry(
      orgId,
      ProductionEntry(
        id: '',
        date: '2026-05-10',
        month: '2026-05',
        staffId: staffIds['Arjun']!,
        staffName: 'Arjun',
        totalAmount: 74.0,
        totalQuantity: 6,
        items: prodItems,
        notes: 'Demo production entry',
        createdBy: ownerId,
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Sample money entry: Arjun advance
    await addMoneyEntry(
      orgId,
      MoneyEntry(
        id: '',
        date: '2026-05-10',
        month: '2026-05',
        staffId: staffIds['Arjun']!,
        staffName: 'Arjun',
        type: MoneyEntryType.advance,
        amount: 20.0,
        notes: 'Demo advance entry',
        createdBy: ownerId,
        createdAt: now,
        updatedAt: now,
      ),
    );

    return orgId;
  }

  // ─── Quotations ──────────────────────────────────────────────

  Stream<List<Quotation>> streamQuotations(String orgId) {
    return _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('quotations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Quotation.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<Quotation?> getQuotationById(String orgId, String quotationId) async {
    final doc = await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('quotations')
        .doc(quotationId)
        .get();

    if (doc.exists) {
      return Quotation.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<String> addQuotation(String orgId, Quotation quotation) async {
    final docRef = _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('quotations')
        .doc();
    
    await docRef.set(quotation.toMap());
    return docRef.id;
  }

  Future<void> updateQuotation(String orgId, Quotation quotation) async {
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('quotations')
        .doc(quotation.id)
        .update(quotation.toMap());
  }

  Future<void> deleteQuotation(String orgId, String quotationId) async {
    await _db
        .collection(Constants.organizationsCollection)
        .doc(orgId)
        .collection('quotations')
        .doc(quotationId)
        .delete();
  }
}
