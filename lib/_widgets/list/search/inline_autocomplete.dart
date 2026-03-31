import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

/// ===== Autocomplete inline =====
class InlineAutocomplete extends StatelessWidget {
  final List<UserData> allUsers;
  final void Function(UserData user) onSelected;
  final VoidCallback onCancel;
  final String? hintText;
  final double popupWidth;

  const InlineAutocomplete({
    super.key,
    required this.allUsers,
    required this.onSelected,
    required this.onCancel,
    this.hintText,
    this.popupWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Autocomplete<UserData>(
            optionsBuilder: (TextEditingValue text) {
              final input = text.text.trim().toLowerCase();
              if (input.isEmpty) return const Iterable.empty();
              return allUsers.where((u) {
                final n = (u.name ?? '').toLowerCase();
                final e = (u.email ?? '').toLowerCase();
                return n.contains(input) || e.contains(input);
              });
            },
            displayStringForOption: (u) =>
            (u.name?.isNotEmpty ?? false) ? '${u.name} (${u.email ?? ''})' : (u.email ?? u.uid ?? ''),
            onSelected: onSelected,
            fieldViewBuilder: (context, textController, focusNode, _) {
              return CustomTextField(
                labelText: hintText,
                controller: textController,
                focusNode: focusNode,
              );
            },
            optionsViewBuilder: (context, onOptionSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: SizedBox(
                    width: popupWidth,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, i) {
                        final u = options.elementAt(i);
                        return ListTile(
                          dense: true,
                          tileColor: Colors.white,
                          onTap: () => onOptionSelected(u),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (u.urlPhoto?.isNotEmpty ?? false)
                                ? NetworkImage(u.urlPhoto!)
                                : null,
                            child: (u.urlPhoto?.isEmpty ?? true)
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Text(u.name ?? u.email ?? u.uid ?? 'Usuário'),
                          subtitle: (u.email?.isNotEmpty ?? false) ? Text(u.email!) : null,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Cancelar',
          icon: const Icon(Icons.close),
          onPressed: onCancel,
        ),
      ],
    );
  }
}
