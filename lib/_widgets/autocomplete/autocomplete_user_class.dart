import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/user/user_data.dart';
import 'package:sisgeo/_utils/responsive_utils.dart';
import '../input/custom_text_field.dart';

class AutocompleteUserClass extends StatefulWidget {
  final String? label;
  final String? Function()? getValue;
  final void Function(String userId)? setValue;
  final List<UserData> allUsers;
  final String? hint;
  final bool enabled;
  final String? Function(String? value)? validator;
  final TextEditingController? controller;

  const AutocompleteUserClass({
    super.key,
    required this.getValue,
    required this.setValue,
    required this.allUsers,
    this.label,
    this.hint,
    required this.enabled,
    this.validator,
    this.controller,
  });

  @override
  State<AutocompleteUserClass> createState() => _AutocompleteUserClassState();
}

class _AutocompleteUserClassState extends State<AutocompleteUserClass> {
  @override
  Widget build(BuildContext context) {
    final selectedUserId = widget.getValue?.call();
    final selectedUser = widget.allUsers.firstWhere(
          (u) => u.id == selectedUserId,
      orElse: () => UserData(id: selectedUserId),
    );

    return Stack(
      children: [
        if (selectedUserId == null || selectedUserId.isEmpty)
          Tooltip(
            message: 'Busque por nome ou email',
            child: SizedBox(
              width: responsiveInputsFourPerLine(context),
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
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return CustomTextField(
                    validator: widget.validator,
                    enabled: widget.enabled,
                    controller: controller,
                    focusNode: focusNode,
                    labelText: widget.label,
                    hint: widget.hint,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final width = responsiveInputsFourPerLine(context);
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
                              onTap: () => onSelected(user),
                              leading: CircleAvatar(
                                backgroundImage: user.urlPhoto?.isNotEmpty == true
                                    ? NetworkImage(user.urlPhoto!)
                                    : null,
                                child: user.urlPhoto?.isEmpty != false
                                    ? const Icon(Icons.person)
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
                onSelected: (user) {
                  setState(() {
                    widget.setValue?.call(user.id!);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.label ?? 'Usuário'} selecionado: ${user.name}')),
                  );
                },
              ),
            ),
          ),

        if (selectedUserId != null && selectedUserId.isNotEmpty)
          Stack(
            children: [
              Container(
                width: responsiveInputsFourPerLine(context),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (selectedUser.urlPhoto?.isNotEmpty ?? false)
                        ? NetworkImage(selectedUser.urlPhoto!)
                        : null,
                    child: (selectedUser.urlPhoto?.isEmpty ?? true)
                        ? widget.enabled ? const Icon(Icons.person)
                        : const Icon(Icons.person, color: Colors.grey) : null,
                  ),
                  title: Text('${selectedUser.name ?? 'Sem nome'} ${selectedUser.surname ?? ''}', style: TextStyle(color: widget.enabled ? Colors.black : Colors.grey)),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: widget.enabled ? () {
                      setState(() {
                        widget.setValue?.call('');
                      });
                    }: null,
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
