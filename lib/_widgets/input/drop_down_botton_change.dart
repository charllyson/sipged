import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';

class DropDownButtonChange extends StatefulWidget {
  const DropDownButtonChange({
    super.key,
    required this.controller,

    // Dados
    this.items = const <String>[],
    this.enabled,
    this.validator,
    this.width,

    // UI
    this.labelText,
    this.greyItems = const <String>{},
    this.menuMaxHeight = 260,
    this.tooltipMessage,

    // Callbacks
    this.onChanged,
    this.onChangedIdLabel, // dispara quando id é conhecido

    // ===== NOVO: seleção por ID =====
    this.selectedId,

    // ===== NOVO: callback de criação externa =====
    this.onCreateNewItem,

    // ===== Firestore (opcional) =====
    this.firestore,
    this.collectionPath,
    this.labelField = 'name',
    this.idField = 'id',
    this.autoLoadWhenEmpty = false,
    this.allowDuplicates = false,

    // Como construir o documento salvo no Firestore (se não informar, usa {labelField: label, idField: id})
    this.buildFirestoreDoc,

    // Prompt para captar o novo item (se não informar, usa um diálogo padrão)
    this.promptForNewItem,

    // Rótulo do item-ação
    this.specialItemLabel = 'Adicionar novo',

    // Quando mostrar o item-ação
    this.showSpecialWhenEmpty = true,
    this.showSpecialAlways = false,

    // Ordenação opcional da lista (ex.: (l) => l..sort())
    this.sortTransformer,

    // ===== Exclusão inline (SUFIXO) =====
    this.enableInlineDelete = true,
    this.confirmDeleteMessage = 'Deseja excluir este item?',
  });

  // Dados básicos
  final TextEditingController controller;
  final List<String> items;
  final bool? enabled;
  final String? Function(String?)? validator;
  final double? width;

  // UI
  final String? labelText;
  final Set<String> greyItems;
  final double menuMaxHeight;
  final String? tooltipMessage;

  // Callbacks
  final void Function(String?)? onChanged;
  final void Function(String id, String label)? onChangedIdLabel;

  // Seleção por ID
  final String? selectedId;

  // Preferido quando a criação é responsabilidade externa (Bloc/Repo).
  final Future<void> Function(String label)? onCreateNewItem;

  // Firestore (opcional)
  final FirebaseFirestore? firestore;
  final String? collectionPath;
  final String labelField;
  final String idField;
  final bool autoLoadWhenEmpty;
  final bool allowDuplicates;

  /// Constrói o documento a partir do id gerado e do label.
  final Map<String, dynamic> Function(String id, String label)? buildFirestoreDoc;

  /// Prompt para captar o nome/label do novo item.
  final Future<String?> Function(BuildContext context)? promptForNewItem;

  /// Título do item-ação na lista
  final String specialItemLabel;

  /// Exibir ação quando a lista estiver vazia
  final bool showSpecialWhenEmpty;

  /// Exibir ação sempre (mesmo se houver itens)
  final bool showSpecialAlways;

  /// Permite ordenar/transformar a lista final apresentada
  final List<String> Function(List<String>)? sortTransformer;

  /// Habilita ícone de lixeira ao lado de cada item
  final bool enableInlineDelete;

  /// Mensagem do diálogo de confirmação
  final String confirmDeleteMessage;

  @override
  State<DropDownButtonChange> createState() => _DropDownButtonChangeState();
}

class _DropDownButtonChangeState extends State<DropDownButtonChange> {
  static const String _kSpecialValue = '__dropdown_action__';

  late List<String> _items;                 // labels
  final Map<String, String> _idByLabel = {}; // label -> id (quando houver)
  String? _selected;                         // label selecionado
  bool _loadingRemote = false;

  String? _lastCollectionPath;
  String? _lastSelectedIdProp;

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
    _applySort();
    _lastCollectionPath = widget.collectionPath;
    _lastSelectedIdProp = widget.selectedId;

    // Seleciona por controller.text inicialmente (caso já exista)
    _selected = _items.contains(widget.controller.text) ? widget.controller.text : null;

    // Tenta carregar remoto se configurado
    _maybeLoadFromFirestore(initial: true);
  }

  @override
  void didUpdateWidget(covariant DropDownButtonChange oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Mudou a lista externa?
    if (oldWidget.items != widget.items) {
      _items = [...widget.items];
      _applySort();
    }

    // Mudou o caminho da coleção? (ex.: troca de empresa)
    if (widget.collectionPath != _lastCollectionPath) {
      _lastCollectionPath = widget.collectionPath;
      // limpa cache de ids e recarrega
      _idByLabel.clear();
      _items = [...(widget.items)];
      _applySort();
      _selected = _items.contains(widget.controller.text) ? widget.controller.text : null;
      _maybeLoadFromFirestore(initial: true);
      setState(() {});
      return;
    }

    // Mudou o selectedId de fora?
    if (widget.selectedId != _lastSelectedIdProp) {
      _lastSelectedIdProp = widget.selectedId;
      _resolveSelectionByIdOrText(preferId: true);
      setState(() {});
      return;
    }

    // Mudou o texto do controller externamente?
    if (oldWidget.controller.text != widget.controller.text &&
        widget.controller.text != _selected) {
      if (_items.contains(widget.controller.text)) {
        _selected = widget.controller.text;
        setState(() {});
      }
    }
  }

  void _applySort() {
    if (widget.sortTransformer != null) {
      _items = widget.sortTransformer!(_items.toList());
    }
  }

  Future<void> _maybeLoadFromFirestore({bool initial = false}) async {
    final shouldLoad = widget.autoLoadWhenEmpty &&
        widget.firestore != null &&
        widget.collectionPath != null &&
        !_loadingRemote;

    if (!shouldLoad) {
      // Mesmo se não for carregar, tente resolver seleção por ID/texto
      _resolveSelectionByIdOrText(preferId: true);
      setState(() {});
      return;
    }

    setState(() => _loadingRemote = true);
    try {
      final snap = await widget.firestore!
          .collection(widget.collectionPath!)
          .orderBy(widget.labelField)
          .get();

      final loadedLabels = <String>[];
      _idByLabel.clear();

      for (final d in snap.docs) {
        final data = d.data();
        final label = (data[widget.labelField] ?? '').toString().trim();
        if (label.isEmpty) continue;
        final id = (data[widget.idField] ?? d.id).toString();
        _idByLabel[label] = id;
        loadedLabels.add(label);
      }

      // Mescla (evita perder itens passados via items)
      final merged = <String>{..._items, ...loadedLabels}.toList();
      _items = merged;
      _applySort();

      // Resolve seleção após carregar
      _resolveSelectionByIdOrText(preferId: true);
    } catch (_) {
      // ignora falha
      _resolveSelectionByIdOrText(preferId: true);
    } finally {
      if (mounted) setState(() => _loadingRemote = false);
    }
  }

  /// Resolve a seleção:
  /// - Se `preferId` e `selectedId` existem, encontra label pelo id.
  /// - Senão, usa o controller.text se estiver na lista.
  void _resolveSelectionByIdOrText({bool preferId = false}) {
    String? resolvedLabel;

    if (preferId && widget.selectedId != null && widget.selectedId!.isNotEmpty) {
      // Procura label por id nos mapeados
      resolvedLabel = _idByLabel.entries
          .firstWhere(
            (e) => e.value == widget.selectedId,
        orElse: () => const MapEntry<String, String>('', ''),
      )
          .key;
      if (resolvedLabel != null && resolvedLabel.isEmpty) {
        resolvedLabel = null;
      }
    }

    // Fallback: controller.text
    resolvedLabel ??=
    (_items.contains(widget.controller.text) ? widget.controller.text : null);

    _selected = resolvedLabel;

    // Atualiza controller se achou label a partir do id
    if (resolvedLabel != null && widget.controller.text != resolvedLabel) {
      widget.controller.text = resolvedLabel;
    }
  }

  TextStyle _styleFor(String value, {bool asSelected = false}) {
    final isGrey = widget.greyItems.contains(value);
    return TextStyle(
      color: isGrey ? Colors.grey : Colors.black,
      fontWeight: asSelected ? FontWeight.w500 : FontWeight.normal,
    );
  }

  Future<void> _deleteItemFromBackend(String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Excluir'),
        content: Text(widget.confirmDeleteMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      if (widget.firestore != null && widget.collectionPath != null) {
        final col = widget.firestore!.collection(widget.collectionPath!);
        final knownId = _idByLabel[label];

        if (knownId != null) {
          await col.doc(knownId).delete();
        } else {
          final qs = await col.where(widget.labelField, isEqualTo: label).get();
          for (final d in qs.docs) {
            await d.reference.delete();
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao excluir "$label".')),
        );
      }
      return;
    }

    setState(() {
      _items.remove(label);
      final removedId = _idByLabel.remove(label);
      if (_selected == label) {
        _selected = null;
        if (widget.controller.text == label) {
          widget.controller.text = '';
        }
      }
      // Se o id removido era o selectedId externo, apenas limpamos a seleção visual
      if (removedId != null && removedId == widget.selectedId) {
        // nada além disso — a prop externa continuará igual até o pai atualizá-la
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item "$label" excluído.')),
      );
    }
  }

  List<DropdownMenuItem<String>> _buildItems() {
    final list = <DropdownMenuItem<String>>[];

    final canInlineDelete = widget.enableInlineDelete &&
        (widget.firestore != null && widget.collectionPath != null) &&
        (widget.enabled ?? true) &&
        !_loadingRemote;

    // Itens normais
    for (final value in _items) {
      list.add(
        DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: _styleFor(value),
                ),
              ),
              if (canInlineDelete) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    await _deleteItemFromBackend(value);
                    setState(() {});
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Item-ação (adicionar)
    final canShowSpecial = widget.specialItemLabel.isNotEmpty &&
        (widget.showSpecialAlways || (widget.showSpecialWhenEmpty && _items.isEmpty));

    if (canShowSpecial) {
      list.add(
        DropdownMenuItem<String>(
          value: _kSpecialValue,
          child: Row(
            children: [
              const Icon(Icons.add, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.specialItemLabel,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return list;
  }

  Future<void> _handleAddNewItem() async {
    final label = await (widget.promptForNewItem != null
        ? widget.promptForNewItem!(context)
        : _defaultPrompt(context));

    if (label == null) return;
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;

    // Duplicidade (por label)
    if (!widget.allowDuplicates &&
        _items.any((e) => e.toLowerCase() == trimmed.toLowerCase())) {
      setState(() {
        _selected = _items.firstWhere(
              (e) => e.toLowerCase() == trimmed.toLowerCase(),
        );
        widget.controller.text = _selected!;
      });
      widget.onChanged?.call(_selected);
      final knownId = _idByLabel[_selected!];
      if (knownId != null && widget.onChangedIdLabel != null) {
        widget.onChangedIdLabel!(knownId, _selected!);
      }
      return;
    }

    // Persistência
    String? createdId;
    if (widget.onCreateNewItem != null) {
      await widget.onCreateNewItem!(trimmed);
    } else if (widget.firestore != null && widget.collectionPath != null) {
      final col = widget.firestore!.collection(widget.collectionPath!);
      final ref = col.doc(); // auto id
      createdId = ref.id;

      final map = widget.buildFirestoreDoc != null
          ? widget.buildFirestoreDoc!(createdId, trimmed)
          : <String, dynamic>{
        widget.labelField: trimmed,
        widget.idField: createdId,
      };

      await ref.set(map);
    }

    // Atualiza local
    setState(() {
      _items = [..._items, trimmed];
      _applySort();
      _selected = trimmed;
      widget.controller.text = trimmed;
      if (createdId != null) {
        _idByLabel[trimmed] = createdId;
      }
    });

    // Callbacks
    widget.onChanged?.call(trimmed);
    final idForLabel = _idByLabel[trimmed];
    if (idForLabel != null && widget.onChangedIdLabel != null) {
      widget.onChangedIdLabel!(idForLabel, trimmed);
    }
  }

  Future<String?> _defaultPrompt(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(widget.specialItemLabel),
        content: CustomTextField(
          controller: ctrl,
          labelText: 'Digite o nome',
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _notifySelection(String? selected) {
    widget.onChanged?.call(selected);
    if (selected != null) {
      final id = _idByLabel[selected];
      if (id != null && widget.onChangedIdLabel != null) {
        widget.onChangedIdLabel!(id, selected);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled ?? true;

    return SizedBox(
      width: widget.width ?? 160,
      child: Tooltip(
        message: widget.tooltipMessage ?? '',
        child: DropdownButtonFormField<String>(
          isDense: true,
          isExpanded: true,
          menuMaxHeight: widget.menuMaxHeight,
          validator: (val) {
            if (val == _kSpecialValue) return null;
            return widget.validator?.call(val);
          },
          dropdownColor: Colors.white,
          value: _selected,
          selectedItemBuilder: (ctx) {
            final values = _buildItems().map((e) => e.value!).toList();
            return values.map((v) {
              final text = v == _kSpecialValue ? widget.specialItemLabel : v;
              final style = v == _kSpecialValue
                  ? const TextStyle(fontWeight: FontWeight.w100, color: Colors.grey)
                  : _styleFor(v, asSelected: true);
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: style,
                ),
              );
            }).toList();
          },
          items: _buildItems(),
          onChanged: (!isEnabled || _loadingRemote)
              ? null
              : (selected) async {
            if (selected == _kSpecialValue) {
              await _handleAddNewItem();
              setState(() {});
              return;
            }
            setState(() {
              _selected = selected;
              widget.controller.text = selected ?? '';
            });
            _notifySelection(selected);
          },
          iconSize: 20,
          decoration: InputDecoration(
            suffixIcon: _loadingRemote
                ? const Padding(
              padding: EdgeInsets.only(right: 10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : null,
            fillColor: isEnabled ? Colors.white : Colors.grey.shade200,
            filled: true,
            labelText: widget.labelText,
            labelStyle:
            TextStyle(color: isEnabled ? Colors.grey : Colors.grey.shade500),
            hintStyle:
            TextStyle(color: isEnabled ? Colors.grey : Colors.grey.shade400),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderSide:
              BorderSide(color: isEnabled ? Colors.grey : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
              BorderSide(color: isEnabled ? Colors.blue : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red.shade700),
              borderRadius: BorderRadius.circular(10),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
