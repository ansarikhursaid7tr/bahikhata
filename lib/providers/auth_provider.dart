import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user_model.dart';
import '../models/organization_model.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Provides the AuthService singleton.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provides the FirestoreService singleton.
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

/// Streams Firebase Auth state.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Fetches the AppUser document from Firestore when auth state changes.
final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return null;

  final firestoreService = ref.read(firestoreServiceProvider);
  try {
    final appUser = await firestoreService.findUserAcrossOrganizations(user.uid);
    if (appUser != null) return appUser;
  } catch (e) {
    print('Error finding user: $e');
  }

  // Auto-setup for owner if no user document exists
  if (user.email == 'owner@bahikhata.local') {
    final orgId = await firestoreService.createOrganization(Organization(
      id: '',
      name: 'My Shop',
      ownerId: user.uid,
      businessType: BusinessType.tailorShop,
      currency: '\$',
      calendarType: 'AD',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    final newAppUser = AppUser(
      id: user.uid,
      uid: user.uid,
      name: 'Owner',
      email: user.email!,
      username: 'owner',
      role: UserRole.owner,
      active: true,
      organizationId: orgId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await firestoreService.createUserDocument(orgId, newAppUser);
    return newAppUser;
  }

  return null;
});

/// Fetches the current organization.
final currentOrganizationProvider = FutureProvider<Organization?>((ref) async {
  final appUser = ref.watch(currentAppUserProvider).value;
  if (appUser == null) return null;

  final firestoreService = ref.read(firestoreServiceProvider);
  return await firestoreService.getOrganization(appUser.organizationId);
});
