// lib/_widgets/timeline/slideTimeLine/photo_timeline_gallery.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/dates/selector/selectorDates.dart';
import 'package:siged/_widgets/list/files/attachment.dart';


typedef PhotoUploadCallback = Future<void> Function();
typedef PhotoDeleteCallback = Future<void> Function(Attachment photo);
typedef PhotoTapCallback = void Function(Attachment photo, List<Attachment> visible);

/// ----------------------------------------------------------------------------
/// PhotoTimelineGallery (reaproveitável)
/// ----------------------------------------------------------------------------
/// - Filtra por ano/mês usando o seu SelectorDates<T>.
/// - Não conhece Firebase/Storage/BLoC; tudo vem por props.
/// ----------------------------------------------------------------------------
class PhotoTimelineGallery extends StatefulWidget {
  const PhotoTimelineGallery({
    super.key,
    required this.photosStream,
    this.onUploadPressed,
    this.onDeletePhoto,
    this.onPhotoTap,
    this.title = 'Galeria de Fotos',
    this.isEditable = true,
    this.gridCrossAxisCount = 4,
    this.gridSpacing = 8,
    this.initialYearMonth, // 'YYYY-MM' ou null => sem filtro inicial
    this.emptyState,
  });

  final Stream<List<Attachment>> photosStream;

  final PhotoUploadCallback? onUploadPressed;
  final PhotoDeleteCallback? onDeletePhoto;
  final PhotoTapCallback? onPhotoTap;

  final String title;
  final bool isEditable;

  final int gridCrossAxisCount;
  final double gridSpacing;

  /// Ex.: '2025-10'. Se null, começa sem filtro.
  final String? initialYearMonth;

  final Widget? emptyState;

  @override
  State<PhotoTimelineGallery> createState() => _PhotoTimelineGalleryState();
}

class _PhotoTimelineGalleryState extends State<PhotoTimelineGallery> {
  // Lista atualmente filtrada pelo SelectorDates
  List<Attachment> _filtered = const [];
  int? _selectedYear;
  int? _selectedMonth;

  int? get _initialYear {
    if (widget.initialYearMonth == null) return null;
    final parts = widget.initialYearMonth!.split('-');
    return int.tryParse(parts[0]);
  }

  int? get _initialMonth {
    if (widget.initialYearMonth == null) return null;
    final parts = widget.initialYearMonth!.split('-');
    return (parts.length > 1) ? int.tryParse(parts[1]) : null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Attachment>>(
      stream: widget.photosStream,
      builder: (context, snap) {
        // ✅ cópia mutável (evita 'Unsupported operation: sort' se chamarmos sort)
        final all = List<Attachment>.from(snap.data ?? const <Attachment>[]);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderBar(
              title: widget.title,
              count: all.length,
              canUpload: widget.isEditable && widget.onUploadPressed != null,
              onPickFiles: widget.onUploadPressed,
            ),
            const SizedBox(height: 8),

            // ====== SELETOR DE ANO/MÊS (seu widget) ======
            SelectorDates<Attachment>(
              items: all,
              getDate: (att) => att.createdAt,
              getLabel: (att) => att.label,
              // Filtro inicial baseado em initialYearMonth (opcional)
              initialYear: _selectedYear ?? _initialYear,
              initialMonth: _selectedMonth ?? _initialMonth,
              // Ordenação aplicada na lista filtrada
              sortByDate: true,
              sortDescending: true, // mais recentes primeiro (coerente com grid)
              onFilterChanged: (filtered) {
                setState(() => _filtered = filtered);
              },
              onSelectionChanged: ({required filteredItems, int? selectedYear, int? selectedMonth}) {
                _selectedYear  = selectedYear;
                _selectedMonth = selectedMonth;
              },
            ),

            const SizedBox(height: 8),

            if (snap.connectionState == ConnectionState.waiting && all.isEmpty)
              const _LoadingPlaceholder()
            else if (_filtered.isEmpty)
              (widget.emptyState ?? _EmptyState(onAdd: widget.isEditable ? widget.onUploadPressed : null))
            else
              _PhotoGrid(
                photos: _filtered,
                crossAxisCount: widget.gridCrossAxisCount,
                spacing: widget.gridSpacing,
                isEditable: widget.isEditable && widget.onDeletePhoto != null,
                onTap: (p) => widget.onPhotoTap?.call(p, _filtered),
                onDelete: (p) => _confirmAndDelete(context, p),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndDelete(BuildContext ctx, Attachment photo) async {
    if (widget.onDeletePhoto == null) return;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Excluir foto'),
        content: const Text('Tem certeza que deseja excluir esta foto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true) {
      await widget.onDeletePhoto!(photo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto excluída.')),
      );
    }
  }
}

/// ============================== SUBWIDGETS ==============================

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.count,
    required this.canUpload,
    required this.onPickFiles,
  });

  final String title;
  final int count;
  final bool canUpload;
  final Future<void> Function()? onPickFiles;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            '$title • $count',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (canUpload)
          FilledButton.icon(
            onPressed: onPickFiles,
            icon: const Icon(Icons.add_a_photo_rounded),
            label: const Text('Adicionar fotos'),
          ),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.crossAxisCount,
    required this.spacing,
    required this.isEditable,
    required this.onTap,
    required this.onDelete,
  });

  final List<Attachment> photos;
  final int crossAxisCount;
  final double spacing;
  final bool isEditable;
  final ValueChanged<Attachment> onTap;
  final ValueChanged<Attachment> onDelete;

  @override
  Widget build(BuildContext context) {
    final cw = MediaQuery.sizeOf(context).width;
    final count = _adaptiveCount(cw, crossAxisCount);
    return GridView.builder(
      itemCount: photos.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
      ),
      itemBuilder: (_, i) {
        final p = photos[i];
        return _PhotoTile(
          photo: p,
          isEditable: isEditable,
          onTap: () => onTap(p),
          onDelete: () => onDelete(p),
        );
      },
    );
  }

  int _adaptiveCount(double width, int base) {
    if (width < 560) return 2;
    if (width < 860) return 3;
    return base;
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.isEditable,
    required this.onTap,
    required this.onDelete,
  });

  final Attachment photo;
  final bool isEditable;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final d = photo.createdAt;
    final dateStr = d == null
        ? ''
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return InkWell(
      onTap: onTap,
      onLongPress: isEditable ? onDelete : null,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photo.url ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Colors.black12,
                  child: Center(child: Icon(Icons.broken_image)),
                ),
                loadingBuilder: (_, child, ev) => ev == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          if (dateStr.isNotEmpty)
            Positioned(
              left: 6,
              bottom: 6,
              child: _Badge(text: dateStr),
            ),
          if (isEditable)
            Positioned(
              right: 2,
              top: 2,
              child: IconButton.filledTonal(
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                tooltip: 'Excluir',
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onAdd});
  final Future<void> Function()? onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Icon(Icons.photo_library_outlined, size: 48, color: Colors.black38),
          const SizedBox(height: 8),
          const Text('Nenhuma foto ainda', style: TextStyle(color: Colors.black54)),
          if (onAdd != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Adicionar fotos'),
            ),
          ],
        ],
      ),
    );
  }
}
