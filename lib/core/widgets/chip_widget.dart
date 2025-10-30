import 'package:flutter/material.dart';
import 'package:taro_mobile/core/constants/colors.dart';

// Updated ChipRow widget with X mark on selected items
class ChipRow extends StatelessWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final Function(String) onToggle;
  final Function(String)? onAddNew;

  const ChipRow({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.onToggle,
    this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 24) / 3;

        final allOptions = <String>[];
        allOptions.addAll(options);

        for (String selected in selectedOptions) {
          if (!options.contains(selected)) {
            allOptions.add(selected);
          }
        }

        return Wrap(
          spacing: 12,
          runSpacing: 15,
          alignment: WrapAlignment.start,
          children:
              allOptions.map((option) {
                final isSelected = selectedOptions.contains(option);
                final isCustom = !options.contains(option);

                return SizedBox(
                  width: itemWidth,
                  child: GestureDetector(
                    onTap: () => onToggle(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.textColor : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.textColor
                                  : (isCustom
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade300),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                isSelected
                                    ? AppColors.textColor.withOpacity(0.25)
                                    : Colors.grey.withOpacity(0.15),
                            blurRadius: isSelected ? 10 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Show X mark for all selected items (both custom and predefined)
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: GestureDetector(
                                onTap: () => onToggle(option),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

class ChipInputField extends StatefulWidget {
  final String label;
  final List<String> selectedItems;
  final Function(String) onAdd;
  final Function(String) onRemove;
  final String? hintText;

  const ChipInputField({
    super.key,
    required this.label,
    required this.selectedItems,
    required this.onAdd,
    required this.onRemove,
    this.hintText,
  });

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _prefixKey = GlobalKey();
  double _prefixWidth = 0;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addItem() {
    final newValue = _controller.text.trim();
    if (newValue.isNotEmpty && !widget.selectedItems.contains(newValue)) {
      widget.onAdd(newValue);
      _controller.clear();
      setState(() {});

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updatePrefixWidth();
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _updatePrefixWidth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_prefixKey.currentContext != null) {
        final RenderBox renderBox =
            _prefixKey.currentContext!.findRenderObject() as RenderBox;
        final newWidth = renderBox.size.width;
        if (newWidth != _prefixWidth) {
          setState(() {
            _prefixWidth = newWidth;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(ChipInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItems.length != widget.selectedItems.length) {
      _updatePrefixWidth();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: widget.selectedItems.isNotEmpty ? null : 58,
          constraints:
              widget.selectedItems.isNotEmpty
                  ? const BoxConstraints(minHeight: 55)
                  : null,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.selectedItems.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        widget.selectedItems.map((item) {
                          return Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 0.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),

                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      color: AppColors.textColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    widget.onRemove(item);
                                    setState(() {});
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),

              SizedBox(
                height: 55,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onSubmitted: (_) => _addItem(),
                  onChanged: (value) => setState(() {}),
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: widget.label,
                    labelStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    hintText: widget.hintText ?? 'Type and press + to add',

                    suffixIcon: IconButton(
                      onPressed: _addItem,
                      icon: Icon(
                        Icons.add_circle,
                        color:
                            _controller.text.trim().isNotEmpty
                                ? AppColors.textColor
                                : Colors.grey.shade400,
                        size: 20,
                      ),
                    ),

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
