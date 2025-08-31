import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';

class AutocompleteUserClass extends StatefulWidget {
  final String? label;
  final TextEditingController controller;
  final List<UserData> allUsers;
  final String? hint;
  final bool enabled;
  final String? Function(String? value)? validator;
  final String? initialUserId;
  final void Function(String userId)? onChanged;

  const AutocompleteUserClass({
    super.key,
    required this.controller,
    required this.allUsers,
    required this.enabled,
    this.label,
    this.hint,
    this.validator,
    this.initialUserId,
    this.onChanged,
  });

  @override
  State<AutocompleteUserClass> createState() => _AutocompleteUserClassState();
}

class _AutocompleteUserClassState extends State<AutocompleteUserClass> {
  String? selectedUserId;

  @override
  void initState() {
    super.initState();
    selectedUserId = widget.initialUserId ?? widget.controller.text;
    widget.controller.text = selectedUserId ?? '';
  }

  void _selectUser(String userId) {
    setState(() {
      selectedUserId = userId;
      widget.controller.text = userId;
    });
    widget.onChanged?.call(userId);
  }

  void _clearSelection() {
    setState(() {
      selectedUserId = '';
      widget.controller.clear();
    });
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.allUsers.firstWhere(
          (u) => u.id == selectedUserId,
      orElse: () => UserData(id: selectedUserId),
    );

    return Stack(
      children: [
        if (selectedUserId == null || selectedUserId!.isEmpty)
          Tooltip(
            message: 'Busque por nome ou email',
            child: Autocomplete<UserData>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable.empty();
                final input = textEditingValue.text.toLowerCase();
                return widget.allUsers.where((user) {
                  final name = user.name?.toLowerCase() ?? '';
                  final email = user.email?.toLowerCase() ?? '';
                  return name.contains(input) || email.contains(input);
                });
              },
              displayStringForOption: (user) => user.name ?? user.email ?? '',
              fieldViewBuilder: (context, textController, focusNode, _) {
                return CustomTextField(
                  validator: widget.validator,
                  enabled: widget.enabled,
                  controller: textController,
                  focusNode: focusNode,
                  labelText: widget.label,
                  hintText: widget.hint,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                final width = responsiveInputWidth(
                  context: context,
                  itemsPerLine: 3,
                  reservedWidth: 98.0,
                  spacing: 12.0,
                  margin: 12.0,
                  extraPadding: 24.0, // padding horizontal somado
                );
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: SizedBox(
                      width: width,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final user = options.elementAt(index);
                          return ListTile(
                            tileColor: Colors.white,
                            onTap: () {
                              onSelected(user);
                            },
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: user.urlPhoto?.isNotEmpty == true
                                  ? NetworkImage(user.urlPhoto!)
                                  : null,
                              child: user.urlPhoto?.isEmpty != false
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            title: Text(user.name ?? ''),
                            subtitle: Text(user.email ?? ''),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (user) => _selectUser(user.id!),
            ),
          ),

        if (selectedUserId != null && selectedUserId!.isNotEmpty)
          Stack(
            children: [
              Container(
                width: responsiveInputWidth(
                  context: context,
                  itemsPerLine: 3,
                  reservedWidth: 98.0,
                  spacing: 12.0,
                  margin: 12.0,
                  extraPadding: 24.0, // padding horizontal somado
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  tileColor: Colors.white,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    backgroundImage: (user.urlPhoto?.isNotEmpty ?? false)
                        ? NetworkImage(user.urlPhoto!)
                        : null,
                    child: (user.urlPhoto?.isEmpty ?? true)
                        ? widget.enabled
                        ? const Icon(Icons.person, color: Colors.grey)
                        : const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    '${user.name ?? 'Sem nome'} ${user.surname ?? ''}',
                    style: TextStyle(color: widget.enabled ? Colors.black : Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: widget.enabled ? _clearSelection : null,
                  ),
                ),
              ),
              if (widget.label != null)
                Positioned(
                  left: 12,
                  top: 0,
                  child: Text(
                    widget.label!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
