import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/user/user_data.dart';
import '../input/custom_text_field.dart';

class AutocompleteUserClass extends StatefulWidget {
  final String? label;
  final String? Function()? getValue;
  final void Function(String userId)? setValue;
  final List<UserData> allUsers;
  final String? hint;

  const AutocompleteUserClass({
    super.key,
    required this.getValue,
    required this.setValue,
    required this.allUsers,
    this.label,
    this.hint,
  });

  @override
  State<AutocompleteUserClass> createState() => _AutocompleteUserClassState();
}

class _AutocompleteUserClassState extends State<AutocompleteUserClass> {
  double getResponsiveWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const spacing = 12.0;
    const margin = 8;
    const horizontalPadding = 32.0;

    if (screenWidth < 600) {
      return screenWidth - margin * 2 - horizontalPadding;
    } else if (screenWidth < 900) {
      return (screenWidth - margin * 2 - spacing * 1 - horizontalPadding) / 2;
    } else if (screenWidth < 1300) {
      return (screenWidth - margin * 2 - spacing * 2 - horizontalPadding) / 3;
    } else {
      return (screenWidth - margin * 2 - spacing * 3 - horizontalPadding) / 4;
    }
  }

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
              width: getResponsiveWidth(context),
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
                    controller: controller,
                    focusNode: focusNode,
                    labelText: widget.label,
                    hint: widget.hint,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final width = getResponsiveWidth(context);

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
                width: getResponsiveWidth(context),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundImage: (selectedUser.urlPhoto?.isNotEmpty ?? false)
                        ? NetworkImage(selectedUser.urlPhoto!)
                        : null,
                    child: (selectedUser.urlPhoto?.isEmpty ?? true)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text('${selectedUser.name ?? 'Sem nome'} ${selectedUser.surname ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        widget.setValue?.call('');
                      });
                    },
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
