import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class BlockScreenToSave extends StatelessWidget {
  const BlockScreenToSave({
    super.key,
    this.loadingStream,
    this.loadingListenable,
    this.isBlocking,
    this.message = 'Salvando os dados ...',
  });

  /// Use quando tiver um Stream<bool> (ex.: bloc)
  final Stream<bool>? loadingStream;

  /// Use quando tiver um ValueListenable<bool> (ex.: ValueNotifier, TextEditingController’s)
  final ValueListenable<bool>? loadingListenable;

  /// Use quando já tem o bool vindo de um Consumer/Selector
  final bool? isBlocking;

  final String message;

  @override
  Widget build(BuildContext context) {
    if (loadingStream != null) {
      return StreamBuilder<bool>(
        stream: loadingStream,
        initialData: false,
        builder: (_, snap) => _buildOverlay(snap.data ?? false),
      );
    }
    if (loadingListenable != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: loadingListenable!,
        builder: (_, value, __) => _buildOverlay(value),
      );
    }
    return _buildOverlay(isBlocking ?? false);
  }

  Widget _buildOverlay(bool blocking) {
    if (!blocking) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: false,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: const _LoadingContent(),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Se tiver seu próprio loader, troque aqui:
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text(
          'Salvando os dados ...',
          style: TextStyle(color: Colors.white, fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
