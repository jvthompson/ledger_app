import 'package:flutter/material.dart';

import '../../editor/workbook_controller.dart';
import '../../util/app_dimens.dart';

/// Same shell as Write's FormattingToolbar (44px, colorScheme.surface,
/// horizontally-scrollable Row), with a name box showing the selected
/// cell's A1 address and a few disabled placeholder buttons to demonstrate
/// matching visual chrome. No real formatting logic yet.
class FormattingToolbar extends StatelessWidget {
  const FormattingToolbar({super.key, required this.controller});

  final WorkbookController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          height: AppDimens.toolbarHeight,
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.toolbarPaddingH),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _NameBox(text: controller.selection.a1),
                const _ToolbarDivider(),
                const _ToggleButton(icon: Icons.format_bold, active: false, onPressed: null),
                const _ToggleButton(icon: Icons.border_all, active: false, onPressed: null),
                const _ToggleButton(icon: Icons.format_color_fill, active: false, onPressed: null),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NameBox extends StatelessWidget {
  const _NameBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: AppDimens.dropdownControlHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: AppDimens.borderColor),
        borderRadius: BorderRadius.circular(AppDimens.toolbarButtonRadius),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.toolbarDividerPaddingH),
      child: const SizedBox(
        height: AppDimens.toolbarDividerHeight,
        child: VerticalDivider(width: 1),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.icon, required this.active, required this.onPressed});

  final IconData icon;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppDimens.toolbarButtonSize,
      height: AppDimens.toolbarButtonSize,
      child: Material(
        color: active ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.toolbarButtonRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.toolbarButtonRadius),
          onTap: onPressed,
          child: Icon(
            icon,
            size: AppDimens.toolbarIconSize,
            color: active ? scheme.onPrimaryContainer : null,
          ),
        ),
      ),
    );
  }
}
