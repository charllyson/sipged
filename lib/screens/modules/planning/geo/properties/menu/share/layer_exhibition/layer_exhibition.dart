import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';

class LayerExhibition extends StatefulWidget {
  final String modeLabelText;
  final String singleLabel;
  final String ruleLabel;
  final bool isRuleMode;
  final ValueChanged<bool> onModeChanged;
  final Widget singleChild;
  final Widget ruleChild;

  const LayerExhibition({
    super.key,
    required this.modeLabelText,
    required this.singleLabel,
    required this.ruleLabel,
    required this.isRuleMode,
    required this.onModeChanged,
    required this.singleChild,
    required this.ruleChild,
  });

  @override
  State<LayerExhibition> createState() => _LayerExhibitionState();
}

class _LayerExhibitionState extends State<LayerExhibition> {
  late final TextEditingController _modeCtrl;

  @override
  void initState() {
    super.initState();
    _modeCtrl = TextEditingController(
      text: widget.isRuleMode ? widget.ruleLabel : widget.singleLabel,
    );
  }

  @override
  void didUpdateWidget(covariant LayerExhibition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isRuleMode != widget.isRuleMode ||
        oldWidget.singleLabel != widget.singleLabel ||
        oldWidget.ruleLabel != widget.ruleLabel) {
      _modeCtrl.text =
      widget.isRuleMode ? widget.ruleLabel : widget.singleLabel;
    }
  }

  @override
  void dispose() {
    _modeCtrl.dispose();
    super.dispose();
  }

  bool _isRuleLabel(String? value) => value == widget.ruleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropDownChange(
                    controller: _modeCtrl,
                    labelText: widget.modeLabelText,
                    width: double.infinity,
                    items: [
                      widget.singleLabel,
                      widget.ruleLabel,
                    ],
                    onChanged: (value) {
                      final nextIsRule = _isRuleLabel(value);
                      if (nextIsRule == widget.isRuleMode) return;
                      widget.onModeChanged(nextIsRule);
                    },
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: widget.isRuleMode
                        ? KeyedSubtree(
                      key: const ValueKey('rule_mode'),
                      child: widget.ruleChild,
                    )
                        : KeyedSubtree(
                      key: const ValueKey('single_mode'),
                      child: widget.singleChild,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}