import 'package:flutter_test/flutter_test.dart';
import 'package:algoverse/features/learning/engine/array_algorithm_executor.dart';


void main() {
  group('Deterministic Array Algorithm Executor Tests (12 Algorithms)', () {
    test('1. arrayTraversal produces complete sequential visit steps', () {
      final trace = ArrayAlgorithmExecutor.execute('arrayTraversal', {
        'array': [5, 3, 8, 1, 9],
      });

      expect(trace.algorithmName, 'arrayTraversal');
      expect(trace.steps.isNotEmpty, true);
      // Each element gets a loop check (line 2) + visit (line 3) + termination step
      expect(trace.steps.length, 5 * 2 + 1);

      // Check first visit
      expect(trace.steps[1].sourceLine, 3);
      expect(trace.steps[1].operation, 'VISIT');
      expect(trace.steps[1].variables['current_value'], 5);

      // Check final termination
      expect(trace.steps.last.sourceLine, 2);
      expect(trace.steps.last.operation, 'DONE');
    });

    test('2. linearSearch produces correct found and not-found traces', () {
      // Found case
      final traceFound = ArrayAlgorithmExecutor.execute('linearSearch', {
        'array': [4, 2, 7, 1, 9],
        'target': 7,
      });
      expect(traceFound.finalResult, 2);
      expect(traceFound.steps.last.operation, 'FOUND');
      expect(traceFound.steps.last.sourceLine, 4);
      expect(traceFound.steps.last.result, '2');

      // Not found case
      final traceNotFound = ArrayAlgorithmExecutor.execute('linearSearch', {
        'array': [4, 2, 7, 1, 9],
        'target': 99,
      });
      expect(traceNotFound.finalResult, -1);
      expect(traceNotFound.steps.last.operation, 'DONE');
      expect(traceNotFound.steps.last.sourceLine, 5);
      expect(traceNotFound.steps.last.result, '-1');
    });

    test('3. findMaximum correctly tracks maximum index', () {
      final trace = ArrayAlgorithmExecutor.execute('findMaximum', {
        'array': [3, 7, 2, 9, 5],
      });
      expect(trace.finalResult, 3); // 9 is at index 3
      expect(trace.steps.first.sourceLine, 2);
      expect(trace.steps.first.variables['max_val'], 3);
      expect(trace.steps.last.sourceLine, 8);
      expect(trace.steps.last.operation, 'DONE');
      expect(trace.steps.last.result, '3');
    });

    test('4. findMinimum correctly tracks minimum index', () {
      final trace = ArrayAlgorithmExecutor.execute('findMinimum', {
        'array': [3, 7, 2, 9, 5],
      });
      expect(trace.finalResult, 2); // 2 is at index 2
      expect(trace.steps.first.sourceLine, 2);
      expect(trace.steps.first.variables['min_val'], 3);
      expect(trace.steps.last.sourceLine, 8);
      expect(trace.steps.last.operation, 'DONE');
      expect(trace.steps.last.result, '2');
    });

    test('5. reverseArray performs in-place element swapping', () {
      final trace = ArrayAlgorithmExecutor.execute('reverseArray', {
        'array': [1, 2, 3, 4, 5],
      });
      expect(trace.finalResult, [5, 4, 3, 2, 1]);

      // Contains swap steps
      final swapSteps =
          trace.steps.where((s) => s.operation == 'SWAP').toList();
      expect(swapSteps.length, 2); // swaps (0,4) and (1,3)
      expect(swapSteps.first.sourceLine, 5);
      expect(trace.steps.last.sourceLine, 8);
    });

    test('6. updateElement updates target index in constant time', () {
      final trace = ArrayAlgorithmExecutor.execute('updateElement', {
        'array': [10, 20, 30, 40],
        'index': 2,
        'value': 99,
      });
      expect(trace.finalResult, [10, 20, 99, 40]);
      expect(trace.steps.any((s) => s.operation == 'UPDATE' && s.sourceLine == 3),
          true);
      expect(trace.steps.last.sourceLine, 4);
    });

    test('7. insertElement shifts elements rightward and inserts new item', () {
      final trace = ArrayAlgorithmExecutor.execute('insertElement', {
        'array': [1, 2, 4, 5],
        'index': 2,
        'value': 3,
      });
      expect(trace.finalResult, [1, 2, 3, 4, 5]);

      // Checks append, shifts, update
      expect(trace.steps[0].operation, 'SHIFT'); // append slot
      expect(trace.steps.any((s) => s.operation == 'UPDATE' && s.sourceLine == 5),
          true);
      expect(trace.steps.last.sourceLine, 6);
    });

    test('8. deleteElement shifts elements leftward and pops end', () {
      final trace = ArrayAlgorithmExecutor.execute('deleteElement', {
        'array': [1, 2, 3, 4, 5],
        'index': 2,
      });
      expect(trace.finalResult, [1, 2, 4, 5]);

      expect(trace.steps.any((s) => s.operation == 'SHIFT' && s.sourceLine == 3),
          true);
      expect(trace.steps.any((s) => s.operation == 'POP' && s.sourceLine == 4),
          true);
      expect(trace.steps.last.sourceLine, 5);
    });

    test('9. twoSum finds matching pair indices', () {
      final trace = ArrayAlgorithmExecutor.execute('twoSum', {
        'array': [3, 2, 4],
        'target': 6,
      });
      expect(trace.finalResult, [1, 2]); // arr[1]=2 + arr[2]=4 == 6
      expect(trace.steps.last.operation, 'FOUND');
      expect(trace.steps.last.sourceLine, 5);
      expect(trace.steps.last.result, '[1, 2]');
    });

    test('10. containsDuplicate identifies duplicates using hash set', () {
      // True case
      final traceTrue = ArrayAlgorithmExecutor.execute('containsDuplicate', {
        'array': [1, 2, 3, 1],
      });
      expect(traceTrue.finalResult, true);
      expect(traceTrue.steps.last.operation, 'FOUND');
      expect(traceTrue.steps.last.sourceLine, 5);

      // False case
      final traceFalse = ArrayAlgorithmExecutor.execute('containsDuplicate', {
        'array': [1, 2, 3, 4],
      });
      expect(traceFalse.finalResult, false);
      expect(traceFalse.steps.last.operation, 'DONE');
      expect(traceFalse.steps.last.sourceLine, 7);
    });

    test('11. kadaneMaxSubarray computes maximum subarray sum', () {
      final trace = ArrayAlgorithmExecutor.execute('kadaneMaxSubarray', {
        'array': [-2, 1, -3, 4, -1, 2, 1, -5, 4],
      });
      expect(trace.finalResult, 6); // [4, -1, 2, 1] sum = 6
      expect(trace.steps.last.sourceLine, 7);
      expect(trace.steps.last.result, '6');
    });

    test('12. bestTimeToBuySellStock calculates single-transaction maximum profit',
        () {
      final trace = ArrayAlgorithmExecutor.execute('bestTimeToBuySellStock', {
        'array': [7, 1, 5, 3, 6, 4],
      });
      expect(trace.finalResult, 5); // buy at 1, sell at 6 -> profit 5
      expect(trace.steps.last.sourceLine, 7);
      expect(trace.steps.last.result, '5');
    });
  });
}
