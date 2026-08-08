// lib/_blocs/system/user/user_repository.dart

import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_firebase.dart';

class UserRepository {
  UserRepository({
    UserFirebase? datasource,
  }) : _datasource = datasource ?? UserFirebase();

  final UserFirebase _datasource;

  Future<UserData?> getById(String uid) {
    return _datasource.getById(uid);
  }

  Future<List<UserData>> getAll({
    int limit = 200,
  }) {
    return _datasource.getAll(limit: limit);
  }

  Future<void> save(UserData user) {
    return _datasource.save(user);
  }

  Future<void> deactivateUser(String uid) {
    return _datasource.deactivateUser(uid);
  }

  Future<void> reactivateUser(String uid) {
    return _datasource.reactivateUser(uid);
  }

  Future<void> blockUser(String uid) {
    return _datasource.blockUser(uid);
  }

  Future<void> softDeleteUser(String uid) {
    return _datasource.softDeleteUser(uid);
  }

  Future<void> hardDeleteUserDocument(String uid) {
    return _datasource.hardDeleteUserDocument(uid);
  }

  Stream<UserData?> currentUserStream() {
    return _datasource.currentUserStream();
  }

  Stream<List<UserData>> usersStream({
    int? limit,
  }) {
    return _datasource.usersStream(limit: limit);
  }

  Future<void> markNotificationSeen(
      String uid,
      String notificationId,
      ) {
    return _datasource.markNotificationSeen(
      uid: uid,
      notificationId: notificationId,
    );
  }

  Future<void> setUserTenantAccess({
    required String uid,
    required List<String> tenantIds,
    String? currentTenantId,
  }) {
    return _datasource.setUserTenantAccess(
      uid: uid,
      tenantIds: tenantIds,
      currentTenantId: currentTenantId,
    );
  }

  Future<void> addTenantToUser({
    required String uid,
    required String tenantId,
    bool makeCurrent = false,
  }) {
    return _datasource.addTenantToUser(
      uid: uid,
      tenantId: tenantId,
      makeCurrent: makeCurrent,
    );
  }

  Future<void> removeTenantFromUser({
    required String uid,
    required String tenantId,
  }) {
    return _datasource.removeTenantFromUser(
      uid: uid,
      tenantId: tenantId,
    );
  }

  Future<void> setCurrentTenantForUser({
    required String uid,
    required String tenantId,
  }) {
    return _datasource.setCurrentTenantForUser(
      uid: uid,
      tenantId: tenantId,
    );
  }

  Future<void> clearUserTenantAccess({
    required String uid,
  }) {
    return _datasource.clearUserTenantAccess(uid: uid);
  }

  Future<UserPagedResult> getAllPaged({
    int pageSize = 50,
    Object? startAfter,
    String orderByField = 'name',
  }) {
    return _datasource.getAllPaged(
      pageSize: pageSize,
      startAfter: startAfter,
      orderByField: orderByField,
    );
  }
}