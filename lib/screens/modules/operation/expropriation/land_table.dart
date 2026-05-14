import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/operation/schedule/expropriation/expropriation_cubit.dart';

class LandTable extends StatefulWidget {
  final String? contractId;
  final String? selectedPropertyId;
  final void Function(String? propertyId)? onPropertySelected;

  const LandTable({
    super.key,
    this.contractId,
    this.selectedPropertyId,
    this.onPropertySelected,
  });

  @override
  State<LandTable> createState() => _LandTableState();
}

class _LandTableState extends State<LandTable> {
  String? _localSelectedId;

  String? get _effectiveSelectedId {
    final external = widget.selectedPropertyId?.trim();

    if (external != null && external.isNotEmpty) {
      return external;
    }

    final local = _localSelectedId?.trim();

    if (local != null && local.isNotEmpty) {
      return local;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();

    _localSelectedId = widget.selectedPropertyId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryLoadProperties();
    });
  }

  @override
  void didUpdateWidget(covariant LandTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedPropertyId != widget.selectedPropertyId) {
      _localSelectedId = widget.selectedPropertyId;
    }

    if (oldWidget.contractId != widget.contractId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tryLoadProperties();
      });
    }
  }

  Future<void> _tryLoadProperties() async {
    final contractId = widget.contractId?.trim();

    if (contractId == null || contractId.isEmpty) return;

    try {
      final cubit = context.read<ExpropriationCubit>() as dynamic;

      try {
        await cubit.loadByContract(contractId);
        return;
      } catch (_) {}

      try {
        await cubit.loadProperties(contractId);
        return;
      } catch (_) {}

      try {
        await cubit.load(contractId);
        return;
      } catch (_) {}

      try {
        await cubit.getAll(contractId);
        return;
      } catch (_) {}
    } catch (_) {}
  }

  List<dynamic> _extractItems(dynamic state) {
    if (state == null) return const <dynamic>[];

    try {
      final list = state.properties;
      if (list is List) return list;
    } catch (_) {}

    try {
      final list = state.landProperties;
      if (list is List) return list;
    } catch (_) {}

    try {
      final list = state.items;
      if (list is List) return list;
    } catch (_) {}

    try {
      final list = state.list;
      if (list is List) return list;
    } catch (_) {}

    try {
      final list = state.data;
      if (list is List) return list;
    } catch (_) {}

    return const <dynamic>[];
  }

  bool _extractLoading(dynamic state) {
    if (state == null) return false;

    try {
      final loading = state.loading;
      if (loading is bool) return loading;
    } catch (_) {}

    try {
      final isLoading = state.isLoading;
      if (isLoading is bool) return isLoading;
    } catch (_) {}

    try {
      final status = state.status;
      final text = status.toString().toLowerCase();
      return text.contains('loading');
    } catch (_) {}

    return false;
  }

  String? _extractError(dynamic state) {
    if (state == null) return null;

    try {
      final error = state.errorMessage;
      if (error != null && error.toString().trim().isNotEmpty) {
        return error.toString();
      }
    } catch (_) {}

    try {
      final error = state.error;
      if (error != null && error.toString().trim().isNotEmpty) {
        return error.toString();
      }
    } catch (_) {}

    return null;
  }

  String _field(dynamic item, List<String> keys) {
    if (item == null) return '';

    if (item is Map) {
      for (final key in keys) {
        final value = item[key];

        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }

      return '';
    }

    for (final key in keys) {
      try {
        final value = _readObjectField(item, key);

        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      } catch (_) {}
    }

    return '';
  }

  dynamic _readObjectField(dynamic item, String key) {
    switch (key) {
      case 'id':
        return item.id;
      case 'propertyId':
        return item.propertyId;
      case 'landPropertyId':
        return item.landPropertyId;
      case 'contractId':
        return item.contractId;
      case 'name':
        return item.name;
      case 'propertyName':
        return item.propertyName;
      case 'title':
        return item.title;
      case 'description':
        return item.description;
      case 'registration':
        return item.registration;
      case 'registrationNumber':
        return item.registrationNumber;
      case 'matricula':
        return item.matricula;
      case 'area':
        return item.area;
      case 'areaM2':
        return item.areaM2;
      case 'areaHa':
        return item.areaHa;
      case 'city':
        return item.city;
      case 'municipio':
        return item.municipio;
      case 'locality':
        return item.locality;
      case 'address':
        return item.address;
      case 'endereco':
        return item.endereco;
      case 'ownerName':
        return item.ownerName;
      case 'proprietario':
        return item.proprietario;
      case 'status':
        return item.status;
    }

    return null;
  }

  String _itemId(dynamic item, int index) {
    final id = _field(
      item,
      const <String>[
        'id',
        'propertyId',
        'landPropertyId',
      ],
    );

    if (id.isNotEmpty) return id;

    return 'property_$index';
  }

  String _name(dynamic item, int index) {
    final value = _field(
      item,
      const <String>[
        'propertyName',
        'name',
        'title',
        'description',
      ],
    );

    if (value.isNotEmpty) return value;

    return 'Imóvel ${index + 1}';
  }

  String _registration(dynamic item) {
    return _field(
      item,
      const <String>[
        'registration',
        'registrationNumber',
        'matricula',
      ],
    );
  }

  String _area(dynamic item) {
    final value = _field(
      item,
      const <String>[
        'area',
        'areaM2',
        'areaHa',
      ],
    );

    if (value.isEmpty) return '-';

    return value;
  }

  String _location(dynamic item) {
    final city = _field(
      item,
      const <String>[
        'city',
        'municipio',
        'locality',
      ],
    );

    final address = _field(
      item,
      const <String>[
        'address',
        'endereco',
      ],
    );

    if (address.isNotEmpty && city.isNotEmpty) {
      return '$address - $city';
    }

    if (address.isNotEmpty) return address;
    if (city.isNotEmpty) return city;

    return '-';
  }

  String _owner(dynamic item) {
    final value = _field(
      item,
      const <String>[
        'ownerName',
        'proprietario',
      ],
    );

    return value.isEmpty ? '-' : value;
  }

  String _status(dynamic item) {
    final value = _field(
      item,
      const <String>[
        'status',
      ],
    );

    return value.isEmpty ? '-' : value;
  }

  void _selectItem(dynamic item, int index) {
    final id = _itemId(item, index);

    setState(() {
      _localSelectedId = id;
    });

    widget.onPropertySelected?.call(id);
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Text(
        'Nenhum imóvel cadastrado para este contrato.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 140,
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpropriationCubit, dynamic>(
      builder: (context, state) {
        final loading = _extractLoading(state);
        final error = _extractError(state);
        final items = _extractItems(state);

        if (loading && items.isEmpty) {
          return _buildLoading();
        }

        if (error != null && items.isEmpty) {
          return _buildError(error);
        }

        if (items.isEmpty) {
          return _buildEmpty();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.08),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF0B1F78),
              ),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              dataTextStyle: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              columnSpacing: 42,
              horizontalMargin: 18,
              showCheckboxColumn: false,
              columns: const [
                DataColumn(
                  label: Text('IMÓVEL'),
                ),
                DataColumn(
                  label: Text('MATRÍCULA'),
                ),
                DataColumn(
                  label: Text('ÁREA'),
                ),
                DataColumn(
                  label: Text('LOCALIZAÇÃO'),
                ),
                DataColumn(
                  label: Text('PROPRIETÁRIO'),
                ),
                DataColumn(
                  label: Text('STATUS'),
                ),
              ],
              rows: List<DataRow>.generate(
                items.length,
                    (index) {
                  final item = items[index];
                  final id = _itemId(item, index);
                  final selected = _effectiveSelectedId == id;

                  return DataRow(
                    selected: selected,
                    color: WidgetStateProperty.resolveWith<Color?>(
                          (states) {
                        if (selected) {
                          return const Color(0xFFEEF4FF);
                        }

                        if (index.isEven) {
                          return const Color(0xFFFAFAFA);
                        }

                        return Colors.white;
                      },
                    ),
                    onSelectChanged: (_) {
                      _selectItem(item, index);
                    },
                    cells: [
                      DataCell(
                        Text(
                          _name(item, index),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(
                        Text(
                          _registration(item).isEmpty
                              ? '-'
                              : _registration(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(
                        Text(
                          _area(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Text(
                            _location(item),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Text(
                            _owner(item),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _status(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}