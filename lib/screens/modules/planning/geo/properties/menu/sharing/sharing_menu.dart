import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/input/auto_complete_change.dart';

class LayerShareUserOption {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;

  const LayerShareUserOption({
    required this.id,
    required this.name,
    this.email,
    this.photoUrl,
  });

  String get subtitle {
    final value = email?.trim() ?? '';
    return value.isEmpty ? id : value;
  }
}

class SharingMenu extends StatefulWidget {
  final List<LayerShareUserOption> allUsers;
  final String? ownerId;
  final String? currentUserId;
  final List<String> selectedUserIds;
  final Map<String, LayerSharePermission> permissionsByUserId;
  final bool isLoadingUsers;
  final String? loadUsersError;
  final void Function(
      List<String> selectedUserIds,
      Map<String, LayerSharePermission> permissionsByUserId,
      )? onChanged;

  const SharingMenu({
    super.key,
    required this.allUsers,
    required this.ownerId,
    required this.currentUserId,
    this.selectedUserIds = const [],
    this.permissionsByUserId = const {},
    this.isLoadingUsers = false,
    this.loadUsersError,
    this.onChanged,
  });

  @override
  State<SharingMenu> createState() => _SharingMenuState();
}

class _SharingMenuState extends State<SharingMenu> {
  final TextEditingController _userController = TextEditingController();

  late List<String> _selectedUserIds;
  late Map<String, LayerSharePermission> _permissionsByUserId;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void didUpdateWidget(covariant SharingMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedUserIds != widget.selectedUserIds ||
        oldWidget.permissionsByUserId != widget.permissionsByUserId ||
        oldWidget.ownerId != widget.ownerId) {
      _hydrate();
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  void _hydrate() {
    final owner = (widget.ownerId ?? '').trim();

    _selectedUserIds = widget.selectedUserIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) => owner.isEmpty || e != owner)
        .toSet()
        .toList(growable: false);

    _permissionsByUserId = Map<String, LayerSharePermission>.from(
      widget.permissionsByUserId,
    );

    _permissionsByUserId.removeWhere((key, value) {
      final uid = key.trim();
      return uid.isEmpty || !_selectedUserIds.contains(uid) || uid == owner;
    });

    for (final uid in _selectedUserIds) {
      _permissionsByUserId.putIfAbsent(
        uid,
            () => LayerSharePermission.readOnly,
      );
    }
  }

  String get _ownerId => (widget.ownerId ?? '').trim();

  List<LayerShareUserOption> get _selectedUsers {
    final selectedSet = _selectedUserIds.toSet();

    return widget.allUsers
        .where((user) => selectedSet.contains(user.id))
        .toList(growable: false);
  }

  List<LayerShareUserOption> get _availableUsers {
    final selectedSet = _selectedUserIds.toSet();

    return widget.allUsers
        .where((user) => user.id.trim().isNotEmpty)
        .where((user) => user.id != _ownerId)
        .where((user) => !selectedSet.contains(user.id))
        .toList(growable: false);
  }

  LayerShareUserOption? get _ownerUser {
    if (_ownerId.isEmpty) return null;

    try {
      return widget.allUsers.firstWhere((user) => user.id == _ownerId);
    } catch (_) {
      return null;
    }
  }

  void _notifyChanged() {
    widget.onChanged?.call(
      List<String>.unmodifiable(_selectedUserIds),
      Map<String, LayerSharePermission>.unmodifiable(_permissionsByUserId),
    );
  }

  void _addUser(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    if (trimmed == _ownerId) return;
    if (_selectedUserIds.contains(trimmed)) return;

    setState(() {
      _selectedUserIds = [..._selectedUserIds, trimmed];
      _permissionsByUserId[trimmed] = LayerSharePermission.readOnly;
      _userController.clear();
    });

    _notifyChanged();
  }

  void _removeUser(String id) {
    setState(() {
      _selectedUserIds = _selectedUserIds
          .where((selectedId) => selectedId != id)
          .toList(growable: false);
      _permissionsByUserId.remove(id);
    });

    _notifyChanged();
  }

  void _changePermission(String id, LayerSharePermission permission) {
    if (!_selectedUserIds.contains(id)) return;

    setState(() {
      _permissionsByUserId[id] = permission;
    });

    _notifyChanged();
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard() {
    final owner = _ownerUser;

    final title = owner?.name.trim().isNotEmpty == true
        ? owner!.name.trim()
        : _ownerId.isNotEmpty
        ? _ownerId
        : 'Proprietário não definido';

    final subtitle = owner?.subtitle ?? 'Usuário proprietário da camada';
    final photo = owner?.photoUrl?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        border: Border.all(color: Colors.indigo.shade100),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.indigo.shade700,
            )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.indigo.shade900,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.indigo.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            avatar: const Icon(Icons.verified_user_outlined, size: 16),
            label: const Text('Proprietário'),
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.indigo.shade100),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedUsersList() {
    final selectedUsers = _selectedUsers;

    if (selectedUsers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Nenhum usuário adicionado ainda.',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: selectedUsers.map((user) {
        final photo = user.photoUrl?.trim() ?? '';
        final permission =
            _permissionsByUserId[user.id] ?? LayerSharePermission.readOnly;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueGrey.shade50,
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? const Icon(
                  Icons.person_outline,
                  size: 16,
                )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<LayerSharePermission>(
                  value: permission,
                  isDense: true,
                  borderRadius: BorderRadius.circular(10),
                  items: LayerSharePermission.values.map((permission) {
                    return DropdownMenuItem<LayerSharePermission>(
                      value: permission,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(permission.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(permission.label),
                        ],
                      ),
                    );
                  }).toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    _changePermission(user.id, value);
                  },
                ),
              ),
              IconButton(
                tooltip: 'Remover compartilhamento',
                onPressed: () => _removeUser(user.id),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUsers = widget.allUsers.isNotEmpty;
    final hasError = (widget.loadUsersError ?? '').trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: RepaintBoundary(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.ios_share_rounded,
                          color: Colors.blueGrey.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Compartilhamento da camada',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Defina o proprietário e os usuários que terão acesso a esta camada.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Proprietário',
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildOwnerCard(),
                    const SizedBox(height: 18),
                    if (widget.isLoadingUsers) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Carregando usuários...',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (hasError) ...[
                      _buildInfoBox(
                        icon: Icons.error_outline,
                        text:
                        'Não foi possível carregar os usuários: ${widget.loadUsersError}',
                        backgroundColor: Colors.red.shade50,
                        borderColor: Colors.red.shade200,
                        iconColor: Colors.red.shade700,
                        textColor: Colors.red.shade900,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!widget.isLoadingUsers && !hasUsers && !hasError) ...[
                      _buildInfoBox(
                        icon: Icons.info_outline,
                        text:
                        'Nenhum usuário disponível para compartilhamento. Verifique se existem usuários na coleção users.',
                        backgroundColor: Colors.orange.shade50,
                        borderColor: Colors.orange.shade200,
                        iconColor: Colors.orange.shade800,
                        textColor: Colors.orange.shade900,
                      ),
                      const SizedBox(height: 16),
                    ],
                    AutoCompleteChange<LayerShareUserOption>(
                      controller: _userController,
                      allList: _availableUsers,
                      enabled: hasUsers && !widget.isLoadingUsers,
                      label: 'Adicionar usuário',
                      hint: 'Digite o nome ou e-mail do usuário',
                      idOf: (user) => user.id,
                      displayOf: (user) => user.name,
                      subtitleOf: (user) => user.subtitle,
                      photoUrlOf: (user) => user.photoUrl,
                      match: (user, queryLower) {
                        final name = user.name.toLowerCase();
                        final email = (user.email ?? '').toLowerCase();
                        final id = user.id.toLowerCase();

                        return name.contains(queryLower) ||
                            email.contains(queryLower) ||
                            id.contains(queryLower);
                      },
                      onChanged: _addUser,
                      validator: null,
                      initialId: null,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Usuários com acesso',
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectedUsersList(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}