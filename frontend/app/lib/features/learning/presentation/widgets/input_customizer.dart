import 'package:flutter/material.dart';

class InputCustomizer extends StatefulWidget {
  final String algorithmName;
  final Map<String, dynamic> defaultInput;
  final ValueChanged<Map<String, dynamic>> onApply;

  const InputCustomizer({
    super.key,
    required this.algorithmName,
    required this.defaultInput,
    required this.onApply,
  });

  @override
  State<InputCustomizer> createState() => _InputCustomizerState();
}

class _InputCustomizerState extends State<InputCustomizer> {
  late TextEditingController _arrayController;
  late TextEditingController _targetController;
  late TextEditingController _indexController;
  late TextEditingController _valueController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.defaultInput);
  }

  @override
  void didUpdateWidget(covariant InputCustomizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.algorithmName != widget.algorithmName) {
      _initControllers(widget.defaultInput);
    }
  }

  void _initControllers(Map<String, dynamic> input) {
    final arr = input['array'] as List?;
    _arrayController = TextEditingController(
      text: arr != null ? arr.join(', ') : '5, 3, 8, 1, 9',
    );
    _targetController = TextEditingController(
      text: input['target']?.toString() ?? '7',
    );
    _indexController = TextEditingController(
      text: input['index']?.toString() ?? '2',
    );
    _valueController = TextEditingController(
      text: input['value']?.toString() ?? '99',
    );
    _errorMessage = null;
  }

  @override
  void dispose() {
    _arrayController.dispose();
    _targetController.dispose();
    _indexController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _apply() {
    setState(() {
      _errorMessage = null;
    });

    try {
      final rawArrayText = _arrayController.text.trim();
      if (rawArrayText.isEmpty) {
        throw Exception('Array cannot be empty.');
      }

      final parsedArray = rawArrayText
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) {
        final numVal = int.tryParse(e);
        if (numVal == null) {
          throw Exception("'$e' is not a valid integer.");
        }
        return numVal;
      }).toList();

      if (parsedArray.length < 3 || parsedArray.length > 10) {
        throw Exception('Array length must be between 3 and 10 elements.');
      }

      final result = <String, dynamic>{'array': parsedArray};

      if (widget.algorithmName == 'linearSearch' ||
          widget.algorithmName == 'twoSum') {
        final targetVal = int.tryParse(_targetController.text.trim());
        if (targetVal == null) {
          throw Exception('Please enter a valid target integer.');
        }
        result['target'] = targetVal;
      }

      if (widget.algorithmName == 'updateElement' ||
          widget.algorithmName == 'insertElement' ||
          widget.algorithmName == 'deleteElement') {
        final idxVal = int.tryParse(_indexController.text.trim());
        if (idxVal == null || idxVal < 0 || idxVal >= parsedArray.length) {
          throw Exception(
            'Index must be between 0 and ${parsedArray.length - 1}.',
          );
        }
        result['index'] = idxVal;
      }

      if (widget.algorithmName == 'updateElement' ||
          widget.algorithmName == 'insertElement') {
        final val = int.tryParse(_valueController.text.trim());
        if (val == null) {
          throw Exception('Please enter a valid value integer.');
        }
        result['value'] = val;
      }

      widget.onApply(result);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _reset() {
    setState(() {
      _initControllers(widget.defaultInput);
    });
    widget.onApply(widget.defaultInput);
  }

  @override
  Widget build(BuildContext context) {
    final needsTarget = widget.algorithmName == 'linearSearch' ||
        widget.algorithmName == 'twoSum';
    final needsIndex = widget.algorithmName == 'updateElement' ||
        widget.algorithmName == 'insertElement' ||
        widget.algorithmName == 'deleteElement';
    final needsValue = widget.algorithmName == 'updateElement' ||
        widget.algorithmName == 'insertElement';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 18, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                'CUSTOMIZE INPUT DATA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.indigo,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Reset', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Array Input Field
          TextField(
            controller: _arrayController,
            decoration: InputDecoration(
              labelText: 'Array Elements (3 to 10 integers, comma-separated)',
              labelStyle: const TextStyle(fontSize: 12),
              hintText: 'e.g. 5, 3, 8, 1, 9',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Additional Parameters Row (Target, Index, Value)
          if (needsTarget || needsIndex || needsValue)
            Row(
              children: [
                if (needsTarget)
                  Expanded(
                    child: TextField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Target Value',
                        labelStyle: const TextStyle(fontSize: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                if (needsIndex) ...[
                  Expanded(
                    child: TextField(
                      controller: _indexController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Target Index',
                        labelStyle: const TextStyle(fontSize: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (needsValue)
                  Expanded(
                    child: TextField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'New Value',
                        labelStyle: const TextStyle(fontSize: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text(
                'APPLY INPUT & REGENERATE TRACE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
