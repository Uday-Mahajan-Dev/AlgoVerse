import 'dart:math' as math;

import '../domain/entities/execution_trace.dart';
import '../domain/entities/visualization_step.dart';

class ArrayAlgorithmExecutor {
  const ArrayAlgorithmExecutor._();

  /// Universal dispatcher for all 12 array algorithm visualizations
  static ExecutionTrace execute(
    String algorithmName,
    Map<String, dynamic> input,
  ) {
    switch (algorithmName) {
      case 'arrayTraversal':
        return traceArrayTraversal(
          _extractIntList(input['array']) ?? [5, 3, 8, 1, 9],
        );
      case 'linearSearch':
        return traceLinearSearch(
          _extractIntList(input['array']) ?? [4, 2, 7, 1, 9],
          _extractInt(input['target']) ?? 7,
        );
      case 'findMaximum':
        return traceFindMaximum(
          _extractIntList(input['array']) ?? [3, 7, 2, 9, 5],
        );
      case 'findMinimum':
        return traceFindMinimum(
          _extractIntList(input['array']) ?? [3, 7, 2, 9, 5],
        );
      case 'reverseArray':
        return traceReverseArray(
          _extractIntList(input['array']) ?? [1, 2, 3, 4, 5],
        );
      case 'updateElement':
        return traceUpdateElement(
          _extractIntList(input['array']) ?? [10, 20, 30, 40],
          _extractInt(input['index']) ?? 2,
          _extractInt(input['value']) ?? 99,
        );
      case 'insertElement':
        return traceInsertElement(
          _extractIntList(input['array']) ?? [1, 2, 4, 5],
          _extractInt(input['index']) ?? 2,
          _extractInt(input['value']) ?? 3,
        );
      case 'deleteElement':
        return traceDeleteElement(
          _extractIntList(input['array']) ?? [1, 2, 3, 4, 5],
          _extractInt(input['index']) ?? 2,
        );
      case 'twoSum':
        return traceTwoSum(
          _extractIntList(input['array']) ?? [3, 2, 4],
          _extractInt(input['target']) ?? 6,
        );
      case 'containsDuplicate':
        return traceContainsDuplicate(
          _extractIntList(input['array']) ?? [1, 2, 3, 1],
        );
      case 'kadaneMaxSubarray':
        return traceKadaneMaxSubarray(
          _extractIntList(input['array']) ?? [-2, 1, -3, 4, -1, 2, 1, -5, 4],
        );
      case 'bestTimeToBuySellStock':
        return traceBestTimeToBuySellStock(
          _extractIntList(input['array']) ?? [7, 1, 5, 3, 6, 4],
        );
      default:
        throw ArgumentError('Unsupported algorithm: $algorithmName');
    }
  }

  // ===========================================================================
  // 1. ARRAY TRAVERSAL (3 lines)
  // 1: def traverse(arr):
  // 2:     for i in range(len(arr)):
  // 3:         visit(arr[i])
  // ===========================================================================
  static ExecutionTrace traceArrayTraversal(List<int> initialArray) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;

    for (int i = 0; i < currentArr.length; i++) {
      // Line 2: Loop check
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 2,
          variables: {'i': i, 'len(arr)': currentArr.length},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'COMPARE',
          explanation: 'Loop iteration i = $i (i < ${currentArr.length}).',
        ),
      );

      // Line 3: Visit element
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 3,
          variables: {
            'i': i,
            'current_value': currentArr[i],
          },
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'VISIT',
          explanation: 'Visiting element at arr[$i] = ${currentArr[i]}.',
        ),
      );
    }

    // Line 2: Loop termination
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 2,
        variables: {'i': currentArr.length},
        arrayState: List<int?>.from(currentArr),
        pointers: {},
        highlights: [],
        operation: 'DONE',
        explanation: 'Traversal complete. Visited all ${currentArr.length} elements.',
        result: 'None',
      ),
    );

    return ExecutionTrace(
      algorithmName: 'arrayTraversal',
      steps: steps,
      finalResult: currentArr,
    );
  }

  // ===========================================================================
  // 2. LINEAR SEARCH (5 lines)
  // 1: def linear_search(arr, target):
  // 2:     for i in range(len(arr)):
  // 3:         if arr[i] == target:
  // 4:             return i
  // 5:     return -1
  // ===========================================================================
  static ExecutionTrace traceLinearSearch(List<int> initialArray, int target) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;
    int? foundIndex;

    for (int i = 0; i < currentArr.length; i++) {
      // Line 2: Loop check
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 2,
          variables: {'i': i, 'target': target},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'COMPARE',
          explanation: 'Checking index i = $i in range 0..${currentArr.length - 1}.',
        ),
      );

      // Line 3: Comparison
      final isMatch = currentArr[i] == target;
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 3,
          variables: {
            'i': i,
            'arr[i]': currentArr[i],
            'target': target,
            'match': isMatch,
          },
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'COMPARE',
          explanation:
              'Comparing arr[$i] (${currentArr[i]}) == target ($target) -> $isMatch.',
        ),
      );

      if (isMatch) {
        foundIndex = i;
        // Line 4: Return index
        steps.add(
          VisualizationStep(
            stepNumber: stepCount++,
            sourceLine: 4,
            variables: {'i': i, 'target': target},
            arrayState: List<int?>.from(currentArr),
            pointers: {'i': i},
            highlights: [i],
            operation: 'FOUND',
            explanation: 'Target $target found at index $i! Returning index $i.',
            result: '$i',
          ),
        );
        break;
      }
    }

    if (foundIndex == null) {
      // Line 5: Return -1
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 5,
          variables: {'target': target},
          arrayState: List<int?>.from(currentArr),
          pointers: {},
          highlights: [],
          operation: 'DONE',
          explanation: 'Target $target not found in array. Returning -1.',
          result: '-1',
        ),
      );
    }

    return ExecutionTrace(
      algorithmName: 'linearSearch',
      steps: steps,
      finalResult: foundIndex ?? -1,
    );
  }

  // ===========================================================================
  // 3. FIND MAXIMUM (8 lines)
  // 1: def find_max(arr):
  // 2:     max_val = arr[0]
  // 3:     max_idx = 0
  // 4:     for i in range(1, len(arr)):
  // 5:         if arr[i] > max_val:
  // 6:             max_val = arr[i]
  // 7:             max_idx = i
  // 8:     return max_idx
  // ===========================================================================
  static ExecutionTrace traceFindMaximum(List<int> initialArray) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;

    int maxVal = currentArr[0]!;
    int maxIdx = 0;

    // Line 2: Initialize max_val
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 2,
        variables: {'max_val': maxVal},
        arrayState: List<int?>.from(currentArr),
        pointers: {'max_idx': 0},
        highlights: [0],
        operation: 'INIT',
        explanation: 'Initialize max_val = arr[0] ($maxVal).',
      ),
    );

    // Line 3: Initialize max_idx
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 3,
        variables: {'max_val': maxVal, 'max_idx': 0},
        arrayState: List<int?>.from(currentArr),
        pointers: {'max_idx': 0},
        highlights: [0],
        operation: 'INIT',
        explanation: 'Initialize max_idx = 0.',
      ),
    );

    for (int i = 1; i < currentArr.length; i++) {
      // Line 4: Loop check
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 4,
          variables: {'i': i, 'max_val': maxVal, 'max_idx': maxIdx},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i, 'max_idx': maxIdx},
          highlights: [i, maxIdx],
          operation: 'COMPARE',
          explanation: 'Loop iteration i = $i (i < ${currentArr.length}).',
        ),
      );

      // Line 5: Compare
      final isGreater = currentArr[i]! > maxVal;
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 5,
          variables: {
            'i': i,
            'arr[i]': currentArr[i],
            'max_val': maxVal,
            'is_greater': isGreater,
          },
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i, 'max_idx': maxIdx},
          highlights: [i, maxIdx],
          operation: 'COMPARE',
          explanation:
              'Comparing arr[$i] (${currentArr[i]}) > max_val ($maxVal) -> $isGreater.',
        ),
      );

      if (isGreater) {
        maxVal = currentArr[i]!;
        // Line 6: Update max_val
        steps.add(
          VisualizationStep(
            stepNumber: stepCount++,
            sourceLine: 6,
            variables: {'i': i, 'max_val': maxVal, 'max_idx': maxIdx},
            arrayState: List<int?>.from(currentArr),
            pointers: {'i': i, 'max_idx': maxIdx},
            highlights: [i],
            operation: 'UPDATE',
            explanation: 'Updated max_val = $maxVal.',
          ),
        );

        maxIdx = i;
        // Line 7: Update max_idx
        steps.add(
          VisualizationStep(
            stepNumber: stepCount++,
            sourceLine: 7,
            variables: {'i': i, 'max_val': maxVal, 'max_idx': maxIdx},
            arrayState: List<int?>.from(currentArr),
            pointers: {'i': i, 'max_idx': maxIdx},
            highlights: [i],
            operation: 'UPDATE',
            explanation: 'Updated max_idx = $maxIdx.',
          ),
        );
      }
    }

    // Line 8: Return max_idx
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 8,
        variables: {'max_val': maxVal, 'max_idx': maxIdx},
        arrayState: List<int?>.from(currentArr),
        pointers: {'max_idx': maxIdx},
        highlights: [maxIdx],
        operation: 'DONE',
        explanation: 'Maximum value $maxVal found at index $maxIdx.',
        result: '$maxIdx',
      ),
    );

    return ExecutionTrace(
      algorithmName: 'findMaximum',
      steps: steps,
      finalResult: maxIdx,
    );
  }

  // ===========================================================================
  // 4. FIND MINIMUM (8 lines)
  // 1: def find_min(arr):
  // 2:     min_val = arr[0]
  // 3:     min_idx = 0
  // 4:     for i in range(1, len(arr)):
  // 5:         if arr[i] < min_val:
  // 6:             min_val = arr[i]
  // 7:             min_idx = i
  // 8:     return min_idx
  // ===========================================================================
  static ExecutionTrace traceFindMinimum(List<int> initialArray) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;

    int minVal = currentArr[0]!;
    int minIdx = 0;

    // Line 2: Initialize min_val
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 2,
        variables: {'min_val': minVal},
        arrayState: List<int?>.from(currentArr),
        pointers: {'min_idx': 0},
        highlights: [0],
        operation: 'INIT',
        explanation: 'Initialize min_val = arr[0] ($minVal).',
      ),
    );

    // Line 3: Initialize min_idx
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 3,
        variables: {'min_val': minVal, 'min_idx': 0},
        arrayState: List<int?>.from(currentArr),
        pointers: {'min_idx': 0},
        highlights: [0],
        operation: 'INIT',
        explanation: 'Initialize min_idx = 0.',
      ),
    );

    for (int i = 1; i < currentArr.length; i++) {
      // Line 4: Loop check
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 4,
          variables: {'i': i, 'min_val': minVal, 'min_idx': minIdx},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i, 'min_idx': minIdx},
          highlights: [i, minIdx],
          operation: 'COMPARE',
          explanation: 'Loop iteration i = $i (i < ${currentArr.length}).',
        ),
      );

      // Line 5: Compare
      final isSmaller = currentArr[i]! < minVal;
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 5,
          variables: {
            'i': i,
            'arr[i]': currentArr[i],
            'min_val': minVal,
            'is_smaller': isSmaller,
          },
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i, 'min_idx': minIdx},
          highlights: [i, minIdx],
          operation: 'COMPARE',
          explanation:
              'Comparing arr[$i] (${currentArr[i]}) < min_val ($minVal) -> $isSmaller.',
        ),
      );

      if (isSmaller) {
        minVal = currentArr[i]!;
        // Line 6: Update min_val
        steps.add(
          VisualizationStep(
            stepNumber: stepCount++,
            sourceLine: 6,
            variables: {'i': i, 'min_val': minVal, 'min_idx': minIdx},
            arrayState: List<int?>.from(currentArr),
            pointers: {'i': i, 'min_idx': minIdx},
            highlights: [i],
            operation: 'UPDATE',
            explanation: 'Updated min_val = $minVal.',
          ),
        );

        minIdx = i;
        // Line 7: Update min_idx
        steps.add(
          VisualizationStep(
            stepNumber: stepCount++,
            sourceLine: 7,
            variables: {'i': i, 'min_val': minVal, 'min_idx': minIdx},
            arrayState: List<int?>.from(currentArr),
            pointers: {'i': i, 'min_idx': minIdx},
            highlights: [i],
            operation: 'UPDATE',
            explanation: 'Updated min_idx = $minIdx.',
          ),
        );
      }
    }

    // Line 8: Return min_idx
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 8,
        variables: {'min_val': minVal, 'min_idx': minIdx},
        arrayState: List<int?>.from(currentArr),
        pointers: {'min_idx': minIdx},
        highlights: [minIdx],
        operation: 'DONE',
        explanation: 'Minimum value $minVal found at index $minIdx.',
        result: '$minIdx',
      ),
    );

    return ExecutionTrace(
      algorithmName: 'findMinimum',
      steps: steps,
      finalResult: minIdx,
    );
  }

  // ===========================================================================
  // 5. REVERSE ARRAY (8 lines)
  // 1: def reverse(arr):
  // 2:     left = 0
  // 3:     right = len(arr) - 1
  // 4:     while left < right:
  // 5:         arr[left], arr[right] = arr[right], arr[left]
  // 6:         left += 1
  // 7:         right -= 1
  // 8:     return arr
  // ===========================================================================
  static ExecutionTrace traceReverseArray(List<int> initialArray) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;

    int left = 0;
    int right = currentArr.length - 1;

    // Line 2: left = 0
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 2,
        variables: {'left': left},
        arrayState: List<int?>.from(currentArr),
        pointers: {'left': left},
        highlights: [left],
        operation: 'INIT',
        explanation: 'Initialize left pointer at index 0.',
      ),
    );

    // Line 3: right = len(arr) - 1
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 3,
        variables: {'left': left, 'right': right},
        arrayState: List<int?>.from(currentArr),
        pointers: {'left': left, 'right': right},
        highlights: [left, right],
        operation: 'INIT',
        explanation: 'Initialize right pointer at index $right.',
      ),
    );

    while (left < right) {
      // Line 4: while left < right
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 4,
          variables: {'left': left, 'right': right},
          arrayState: List<int?>.from(currentArr),
          pointers: {'left': left, 'right': right},
          highlights: [left, right],
          operation: 'COMPARE',
          explanation: 'Check condition left < right ($left < $right) -> True.',
        ),
      );

      // Line 5: Swap
      final temp = currentArr[left];
      currentArr[left] = currentArr[right];
      currentArr[right] = temp;

      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 5,
          variables: {
            'left': left,
            'right': right,
            'swapped': '[${currentArr[left]}, ${currentArr[right]}]',
          },
          arrayState: List<int?>.from(currentArr),
          pointers: {'left': left, 'right': right},
          highlights: [left, right],
          operation: 'SWAP',
          explanation:
              'Swapped arr[$left] (${currentArr[left]}) with arr[$right] (${currentArr[right]}).',
        ),
      );

      // Line 6: left += 1
      left++;
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 6,
          variables: {'left': left, 'right': right},
          arrayState: List<int?>.from(currentArr),
          pointers: {'left': left, 'right': right},
          highlights: [left],
          operation: 'UPDATE',
          explanation: 'Incremented left pointer to $left.',
        ),
      );

      // Line 7: right -= 1
      right--;
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 7,
          variables: {'left': left, 'right': right},
          arrayState: List<int?>.from(currentArr),
          pointers: {'left': left, 'right': right},
          highlights: [right],
          operation: 'UPDATE',
          explanation: 'Decremented right pointer to $right.',
        ),
      );
    }

    // Line 4: Loop exit check
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 4,
        variables: {'left': left, 'right': right},
        arrayState: List<int?>.from(currentArr),
        pointers: (left <= right) ? {'left': left, 'right': right} : {},
        highlights: [],
        operation: 'COMPARE',
        explanation: 'Check condition left < right ($left < $right) -> False. Loop terminated.',
      ),
    );

    // Line 8: Return arr
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 8,
        variables: {'left': left, 'right': right},
        arrayState: List<int?>.from(currentArr),
        pointers: {},
        highlights: [],
        operation: 'DONE',
        explanation: 'Array reversed in-place successfully.',
        result: '$currentArr',
      ),
    );

    return ExecutionTrace(
      algorithmName: 'reverseArray',
      steps: steps,
      finalResult: currentArr,
    );
  }

  // ===========================================================================
  // 6. UPDATE ELEMENT (4 lines)
  // 1: def update(arr, index, value):
  // 2:     if 0 <= index < len(arr):
  // 3:         arr[index] = value
  // 4:     return arr
  // ===========================================================================
  static ExecutionTrace traceUpdateElement(
    List<int> initialArray,
    int index,
    int value,
  ) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;

    final inBounds = index >= 0 && index < currentArr.length;

    // Line 2: Bounds check
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 2,
        variables: {'index': index, 'value': value, 'in_bounds': inBounds},
        arrayState: List<int?>.from(currentArr),
        pointers: inBounds ? {'index': index} : {},
        highlights: inBounds ? [index] : [],
        operation: 'COMPARE',
        explanation: 'Checking if index $index is within bounds 0..${currentArr.length - 1} -> $inBounds.',
      ),
    );

    if (inBounds) {
      currentArr[index] = value;
      // Line 3: Update element
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 3,
          variables: {'index': index, 'value': value},
          arrayState: List<int?>.from(currentArr),
          pointers: {'index': index},
          highlights: [index],
          operation: 'UPDATE',
          explanation: 'Updated arr[$index] to $value.',
        ),
      );
    }

    // Line 4: Return arr
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 4,
        variables: {'index': index, 'value': value},
        arrayState: List<int?>.from(currentArr),
        pointers: inBounds ? {'index': index} : {},
        highlights: inBounds ? [index] : [],
        operation: 'DONE',
        explanation: 'Returned array with updated element.',
        result: '$currentArr',
      ),
    );

    return ExecutionTrace(
      algorithmName: 'updateElement',
      steps: steps,
      finalResult: currentArr,
    );
  }

  // ===========================================================================
  // 7. INSERT ELEMENT (RIGHT SHIFT) (6 lines)
  // 1: def insert(arr, index, value):
  // 2:     arr.append(None)
  // 3:     for i in range(len(arr) - 1, index, -1):
  // 4:         arr[i] = arr[i - 1]
  // 5:     arr[index] = value
  // 6:     return arr
  // ===========================================================================
  static ExecutionTrace traceInsertElement(
    List<int> initialArray,
    int index,
    int value,
  ) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;

    // Line 2: Append None
    currentArr.add(null);
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 2,
        variables: {'index': index, 'value': value},
        arrayState: List<int?>.from(currentArr),
        pointers: {'index': index, 'new_slot': currentArr.length - 1},
        highlights: [currentArr.length - 1],
        operation: 'SHIFT',
        explanation: 'Appended vacant slot at end of array (size = ${currentArr.length}).',
      ),
    );

    // Line 3 & 4: Shift elements rightwards
    for (int i = currentArr.length - 1; i > index; i--) {
      // Line 3: Loop check
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 3,
          variables: {'i': i, 'index': index},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i, 'index': index},
          highlights: [i, i - 1],
          operation: 'COMPARE',
          explanation: 'Shift loop at index i = $i (shifting element from ${i - 1}).',
        ),
      );

      currentArr[i] = currentArr[i - 1];
      currentArr[i - 1] = null; // visual representation of shift motion

      // Line 4: Shift execution
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 4,
          variables: {'i': i, 'shifted_val': currentArr[i]},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i, 'index': index},
          highlights: [i],
          operation: 'SHIFT',
          explanation: 'Shifted element ${currentArr[i]} rightwards into arr[$i].',
        ),
      );
    }

    // Line 5: Insert value at target index
    currentArr[index] = value;
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 5,
        variables: {'index': index, 'value': value},
        arrayState: List<int?>.from(currentArr),
        pointers: {'index': index},
        highlights: [index],
        operation: 'UPDATE',
        explanation: 'Inserted value $value into vacant slot arr[$index].',
      ),
    );

    // Line 6: Return array
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 6,
        variables: {'index': index, 'value': value},
        arrayState: List<int?>.from(currentArr),
        pointers: {},
        highlights: [index],
        operation: 'DONE',
        explanation: 'Insertion completed successfully.',
        result: '$currentArr',
      ),
    );

    return ExecutionTrace(
      algorithmName: 'insertElement',
      steps: steps,
      finalResult: currentArr,
    );
  }

  // ===========================================================================
  // 8. DELETE ELEMENT (LEFT SHIFT) (5 lines)
  // 1: def delete(arr, index):
  // 2:     for i in range(index, len(arr) - 1):
  // 3:         arr[i] = arr[i + 1]
  // 4:     arr.pop()
  // 5:     return arr
  // ===========================================================================
  static ExecutionTrace traceDeleteElement(List<int> initialArray, int index) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;

    // Line 2 & 3: Shift elements leftwards
    for (int i = index; i < currentArr.length - 1; i++) {
      // Line 2: Loop check
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 2,
          variables: {'i': i, 'index': index},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i, 'next': i + 1},
          highlights: [i, i + 1],
          operation: 'COMPARE',
          explanation: 'Shift loop at i = $i: pulling element from index ${i + 1}.',
        ),
      );

      currentArr[i] = currentArr[i + 1];

      // Line 3: Shift copy
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 3,
          variables: {'i': i, 'copied_val': currentArr[i]},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'SHIFT',
          explanation: 'Overwrote arr[$i] with arr[${i + 1}] (${currentArr[i]}).',
        ),
      );
    }

    // Line 4: arr.pop()
    final popped = currentArr.removeLast();
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 4,
        variables: {'popped': popped, 'new_len': currentArr.length},
        arrayState: List<int?>.from(currentArr),
        pointers: {},
        highlights: [],
        operation: 'POP',
        explanation: 'Popped trailing duplicate slot to finalize deletion.',
      ),
    );

    // Line 5: Return arr
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 5,
        variables: {'final_len': currentArr.length},
        arrayState: List<int?>.from(currentArr),
        pointers: {},
        highlights: [],
        operation: 'DONE',
        explanation: 'Element deleted and array compacted.',
        result: '$currentArr',
      ),
    );

    return ExecutionTrace(
      algorithmName: 'deleteElement',
      steps: steps,
      finalResult: currentArr,
    );
  }

  // ===========================================================================
  // 9. TWO SUM (6 lines)
  // 1: def two_sum(arr, target):
  // 2:     for i in range(len(arr)):
  // 3:         for j in range(i + 1, len(arr)):
  // 4:             if arr[i] + arr[j] == target:
  // 5:                 return [i, j]
  // 6:     return []
  // ===========================================================================
  static ExecutionTrace traceTwoSum(List<int> initialArray, int target) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;
    List<int>? foundIndices;

    for (int i = 0; i < currentArr.length; i++) {
      // Line 2: Outer loop
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 2,
          variables: {'i': i, 'target': target},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'COMPARE',
          explanation: 'Outer loop pointer i = $i.',
        ),
      );

      for (int j = i + 1; j < currentArr.length; j++) {
        // Line 3: Inner loop
        steps.add(
          VisualizationStep(
            stepNumber: stepCount++,
            sourceLine: 3,
            variables: {'i': i, 'j': j, 'target': target},
            arrayState: List<int?>.from(currentArr),
            pointers: {'i': i, 'j': j},
            highlights: [i, j],
            operation: 'COMPARE',
            explanation: 'Inner loop pointer j = $j.',
          ),
        );

        final sum = currentArr[i]! + currentArr[j]!;
        final isMatch = sum == target;

        // Line 4: Check if sum == target
        steps.add(
          VisualizationStep(
            stepNumber: stepCount++,
            sourceLine: 4,
            variables: {
              'i': i,
              'j': j,
              'arr[i]': currentArr[i],
              'arr[j]': currentArr[j],
              'sum': sum,
              'target': target,
            },
            arrayState: List<int?>.from(currentArr),
            pointers: {'i': i, 'j': j},
            highlights: [i, j],
            operation: 'COMPARE',
            explanation:
                'Checking arr[$i] (${currentArr[i]}) + arr[$j] (${currentArr[j]}) = $sum == $target -> $isMatch.',
          ),
        );

        if (isMatch) {
          foundIndices = [i, j];
          // Line 5: Return [i, j]
          steps.add(
            VisualizationStep(
              stepNumber: stepCount++,
              sourceLine: 5,
              variables: {'i': i, 'j': j, 'result': '[$i, $j]'},
              arrayState: List<int?>.from(currentArr),
              pointers: {'i': i, 'j': j},
              highlights: [i, j],
              operation: 'FOUND',
              explanation:
                  'Two sum target $target matched! Returning pair [$i, $j].',
              result: '[$i, $j]',
            ),
          );
          break;
        }
      }

      if (foundIndices != null) break;
    }

    if (foundIndices == null) {
      // Line 6: Return []
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 6,
          variables: {'target': target},
          arrayState: List<int?>.from(currentArr),
          pointers: {},
          highlights: [],
          operation: 'DONE',
          explanation: 'No two numbers sum to target $target. Returning [].',
          result: '[]',
        ),
      );
    }

    return ExecutionTrace(
      algorithmName: 'twoSum',
      steps: steps,
      finalResult: foundIndices ?? [],
    );
  }

  // ===========================================================================
  // 10. CONTAINS DUPLICATE (7 lines)
  // 1: def contains_duplicate(arr):
  // 2:     seen = set()
  // 3:     for i in range(len(arr)):
  // 4:         if arr[i] in seen:
  // 5:             return True
  // 6:         seen.add(arr[i])
  // 7:     return False
  // ===========================================================================
  static ExecutionTrace traceContainsDuplicate(List<int> initialArray) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;

    final seen = <int>{};
    bool duplicateFound = false;

    // Line 2: seen = set()
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 2,
        variables: {'seen': []},
        arrayState: List<int?>.from(currentArr),
        pointers: {},
        highlights: [],
        operation: 'INIT',
        explanation: 'Initialize empty seen set.',
      ),
    );

    for (int i = 0; i < currentArr.length; i++) {
      // Line 3: Loop check
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 3,
          variables: {'i': i, 'seen': seen.toList()},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'COMPARE',
          explanation: 'Inspecting index i = $i (element ${currentArr[i]}).',
        ),
      );

      final val = currentArr[i]!;
      final isDuplicate = seen.contains(val);

      // Line 4: if arr[i] in seen
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 4,
          variables: {
            'i': i,
            'val': val,
            'seen': seen.toList(),
            'is_duplicate': isDuplicate,
          },
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'COMPARE',
          explanation:
              'Checking if $val is in seen $seen -> $isDuplicate.',
        ),
      );

      if (isDuplicate) {
        duplicateFound = true;
        // Line 5: return True
        steps.add(
          VisualizationStep(
            stepNumber: stepCount++,
            sourceLine: 5,
            variables: {'i': i, 'val': val, 'seen': seen.toList()},
            arrayState: List<int?>.from(currentArr),
            pointers: {'i': i},
            highlights: [i],
            operation: 'FOUND',
            explanation: 'Duplicate found: $val already in set. Returning True.',
            result: 'True',
          ),
        );
        break;
      }

      // Line 6: seen.add(arr[i])
      seen.add(val);
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 6,
          variables: {'i': i, 'seen': seen.toList()},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'UPDATE',
          explanation: 'Added $val to seen set ($seen).',
        ),
      );
    }

    if (!duplicateFound) {
      // Line 7: return False
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 7,
          variables: {'seen': seen.toList()},
          arrayState: List<int?>.from(currentArr),
          pointers: {},
          highlights: [],
          operation: 'DONE',
          explanation: 'All elements unique. Returning False.',
          result: 'False',
        ),
      );
    }

    return ExecutionTrace(
      algorithmName: 'containsDuplicate',
      steps: steps,
      finalResult: duplicateFound,
    );
  }

  // ===========================================================================
  // 11. KADANE MAXIMUM SUBARRAY (7 lines)
  // 1: def max_subarray(arr):
  // 2:     best = arr[0]
  // 3:     current = arr[0]
  // 4:     for i in range(1, len(arr)):
  // 5:         current = max(arr[i], current + arr[i])
  // 6:         best = max(best, current)
  // 7:     return best
  // ===========================================================================
  static ExecutionTrace traceKadaneMaxSubarray(List<int> initialArray) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;

    int best = currentArr[0]!;
    int current = currentArr[0]!;

    // Line 2: best = arr[0]
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 2,
        variables: {'best': best},
        arrayState: List<int?>.from(currentArr),
        pointers: {'i': 0},
        highlights: [0],
        operation: 'INIT',
        explanation: 'Initialize best = arr[0] ($best).',
      ),
    );

    // Line 3: current = arr[0]
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 3,
        variables: {'best': best, 'current': current},
        arrayState: List<int?>.from(currentArr),
        pointers: {'i': 0},
        highlights: [0],
        operation: 'INIT',
        explanation: 'Initialize current subarray sum = arr[0] ($current).',
      ),
    );

    for (int i = 1; i < currentArr.length; i++) {
      // Line 4: Loop check
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 4,
          variables: {'i': i, 'current': current, 'best': best},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'COMPARE',
          explanation: 'Iterating index i = $i (val = ${currentArr[i]}).',
        ),
      );

      final val = currentArr[i]!;
      final extended = current + val;
      current = math.max(val, extended);

      // Line 5: current = max(...)
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 5,
          variables: {
            'i': i,
            'val': val,
            'extended_sum': extended,
            'current': current,
            'best': best,
          },
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'UPDATE',
          explanation:
              'current = max($val, ${extended - val} + $val) = $current.',
        ),
      );

      final oldBest = best;
      best = math.max(best, current);

      // Line 6: best = max(...)
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 6,
          variables: {'i': i, 'current': current, 'best': best},
          arrayState: List<int?>.from(currentArr),
          pointers: {'i': i},
          highlights: [i],
          operation: 'UPDATE',
          explanation: 'best = max($oldBest, $current) = $best.',
        ),
      );
    }

    // Line 7: return best
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 7,
        variables: {'best': best, 'current': current},
        arrayState: List<int?>.from(currentArr),
        pointers: {},
        highlights: [],
        operation: 'DONE',
        explanation: 'Maximum subarray sum is $best.',
        result: '$best',
      ),
    );

    return ExecutionTrace(
      algorithmName: 'kadaneMaxSubarray',
      steps: steps,
      finalResult: best,
    );
  }

  // ===========================================================================
  // 12. BEST TIME TO BUY AND SELL STOCK (7 lines)
  // 1: def max_profit(prices):
  // 2:     min_price = prices[0]
  // 3:     best = 0
  // 4:     for i in range(1, len(prices)):
  // 5:         best = max(best, prices[i] - min_price)
  // 6:         min_price = min(min_price, prices[i])
  // 7:     return best
  // ===========================================================================
  static ExecutionTrace traceBestTimeToBuySellStock(List<int> initialArray) {
    final steps = <VisualizationStep>[];
    final currentArr = List<int?>.from(initialArray);
    int stepCount = 0;

    int minPrice = currentArr[0]!;
    int best = 0;

    // Line 2: min_price = prices[0]
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 2,
        variables: {'min_price': minPrice},
        arrayState: List<int?>.from(currentArr),
        pointers: {'min_day': 0},
        highlights: [0],
        operation: 'INIT',
        explanation: 'Initialize min_price = prices[0] ($minPrice).',
      ),
    );

    // Line 3: best = 0
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 3,
        variables: {'min_price': minPrice, 'best': 0},
        arrayState: List<int?>.from(currentArr),
        pointers: {'min_day': 0},
        highlights: [0],
        operation: 'INIT',
        explanation: 'Initialize best profit = 0.',
      ),
    );

    for (int i = 1; i < currentArr.length; i++) {
      // Line 4: Loop check
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 4,
          variables: {'i': i, 'min_price': minPrice, 'best': best},
          arrayState: List<int?>.from(currentArr),
          pointers: {'day': i},
          highlights: [i],
          operation: 'COMPARE',
          explanation: 'Inspecting day i = $i (price = ${currentArr[i]}).',
        ),
      );

      final price = currentArr[i]!;
      final currentProfit = price - minPrice;
      best = math.max(best, currentProfit);

      // Line 5: best = max(...)
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 5,
          variables: {
            'i': i,
            'price': price,
            'min_price': minPrice,
            'today_profit': currentProfit,
            'best': best,
          },
          arrayState: List<int?>.from(currentArr),
          pointers: {'day': i},
          highlights: [i],
          operation: 'UPDATE',
          explanation:
              'Profit if sold on day $i: $price - $minPrice = $currentProfit. Best profit: $best.',
        ),
      );

      final oldMin = minPrice;
      minPrice = math.min(minPrice, price);

      // Line 6: min_price = min(...)
      steps.add(
        VisualizationStep(
          stepNumber: stepCount++,
          sourceLine: 6,
          variables: {'i': i, 'min_price': minPrice, 'best': best},
          arrayState: List<int?>.from(currentArr),
          pointers: {'day': i},
          highlights: [i],
          operation: 'UPDATE',
          explanation: 'min_price = min($oldMin, $price) = $minPrice.',
        ),
      );
    }

    // Line 7: return best
    steps.add(
      VisualizationStep(
        stepNumber: stepCount++,
        sourceLine: 7,
        variables: {'best': best, 'min_price': minPrice},
        arrayState: List<int?>.from(currentArr),
        pointers: {},
        highlights: [],
        operation: 'DONE',
        explanation: 'Maximum achievable profit is $best.',
        result: '$best',
      ),
    );

    return ExecutionTrace(
      algorithmName: 'bestTimeToBuySellStock',
      steps: steps,
      finalResult: best,
    );
  }

  // ===========================================================================
  // HELPER UTILITIES
  // ===========================================================================
  static List<int>? _extractIntList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => (e is num) ? e.toInt() : int.tryParse(e.toString()) ?? 0)
          .toList();
    }
    return null;
  }

  static int? _extractInt(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw != null) return int.tryParse(raw.toString());
    return null;
  }
}
