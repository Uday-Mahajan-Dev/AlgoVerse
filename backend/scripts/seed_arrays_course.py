import sys
from pathlib import Path
import uuid

# Ensure app package is discoverable
sys.path.append(str(Path(__file__).resolve().parent.parent))

import app.db.base  # noqa: F401
from app.db.session import SessionLocal
from app.models.course import Course
from app.models.course_module import CourseModule
from app.models.lesson import Lesson
from app.models.user import User


# ==============================================================================
# CANONICAL CODE SNIPPETS (CRITICAL INTEGRATION CONTRACT FOR PHASE D TRACER)
# ==============================================================================

SNIPPET_ARRAY_TRAVERSAL = """def traverse(arr):
    for i in range(len(arr)):
        visit(arr[i])"""

SNIPPET_UPDATE_ELEMENT = """def update(arr, index, value):
    if 0 <= index < len(arr):
        arr[index] = value
    return arr"""

SNIPPET_INSERT_ELEMENT = """def insert(arr, index, value):
    arr.append(None)
    for i in range(len(arr) - 1, index, -1):
        arr[i] = arr[i - 1]
    arr[index] = value
    return arr"""

SNIPPET_DELETE_ELEMENT = """def delete(arr, index):
    for i in range(index, len(arr) - 1):
        arr[i] = arr[i + 1]
    arr.pop()
    return arr"""

SNIPPET_LINEAR_SEARCH = """def linear_search(arr, target):
    for i in range(len(arr)):
        if arr[i] == target:
            return i
    return -1"""

SNIPPET_FIND_MAXIMUM = """def find_max(arr):
    max_val = arr[0]
    max_idx = 0
    for i in range(1, len(arr)):
        if arr[i] > max_val:
            max_val = arr[i]
            max_idx = i
    return max_idx"""

SNIPPET_FIND_MINIMUM = """def find_min(arr):
    min_val = arr[0]
    min_idx = 0
    for i in range(1, len(arr)):
        if arr[i] < min_val:
            min_val = arr[i]
            min_idx = i
    return min_idx"""

SNIPPET_REVERSE_ARRAY = """def reverse(arr):
    left = 0
    right = len(arr) - 1
    while left < right:
        arr[left], arr[right] = arr[right], arr[left]
        left += 1
        right -= 1
    return arr"""

SNIPPET_TWO_SUM = """def two_sum(arr, target):
    for i in range(len(arr)):
        for j in range(i + 1, len(arr)):
            if arr[i] + arr[j] == target:
                return [i, j]
    return []"""

SNIPPET_CONTAINS_DUPLICATE = """def contains_duplicate(arr):
    seen = set()
    for i in range(len(arr)):
        if arr[i] in seen:
            return True
        seen.add(arr[i])
    return False"""

SNIPPET_KADANE = """def max_subarray(arr):
    best = arr[0]
    current = arr[0]
    for i in range(1, len(arr)):
        current = max(arr[i], current + arr[i])
        best = max(best, current)
    return best"""

SNIPPET_BUY_SELL_STOCK = """def max_profit(prices):
    min_price = prices[0]
    best = 0
    for i in range(1, len(prices)):
        best = max(best, prices[i] - min_price)
        min_price = min(min_price, prices[i])
    return best"""


# ==============================================================================
# SEED SPECIFICATION DEFINITION
# ==============================================================================

ARRAYS_COURSE_SPEC = {
    "title": "Data Structures & Algorithms: Arrays",
    "slug": "arrays",
    "description": "Master array fundamentals, operations, and classic interview patterns through interactive step-by-step visualizations.",
    "difficulty": "BEGINNER",
    "topic_category": "Data Structures",
    "thumbnail_url": "https://images.unsplash.com/photo-1516116211227-bbc13f17316a?w=800&auto=format&fit=crop&q=80",
    "is_published": True,
    "modules": [
        # ----------------------------------------------------------------------
        # MODULE 1: Array Fundamentals
        # ----------------------------------------------------------------------
        {
            "title": "Array Fundamentals",
            "order_index": 1,
            "lessons": [
                {
                    "title": "What is an Array?",
                    "slug": "what-is-an-array",
                    "content_type": "CONCEPT",
                    "order_index": 1,
                    "estimated_minutes": 10,
                    "content_json": {
                        "concept_text": "An array is a fundamental linear data structure that stores elements of the same data type in contiguous memory locations. Because memory addresses follow one another sequentially without gaps, calculating the exact byte location of any item takes constant O(1) time.\n\nIn low-level architecture, an array is defined by its base memory pointer and element size. When you declare an array of integers of size N, the system allocates a block of bytes equal to N * sizeof(integer). Each element can be instantly accessed using index arithmetic.\n\nArrays form the bedrock of almost every other data structure, including stacks, queues, hash table buckets, heap priority queues, and dynamic strings. Their physical layout optimizes CPU hardware cache lines through spatial locality, allowing rapid batch loading into L1/L2 caches.",
                        "key_points": [
                            "Contiguous physical memory allocation allows instant address computation: Base + i * ElementSize.",
                            "Direct random access takes O(1) time regardless of array size.",
                            "Homogeneous data typing guarantees uniform byte allocation across every slot.",
                            "Hardware spatial locality enhances CPU cache line prefetching for blazing fast sequential access."
                        ],
                        "examples": [
                            {
                                "title": "Memory Address Offset in Fixed Arrays",
                                "code": "# Concept: Address(A[i]) = Base_Address + i * sizeof(T)\nnumbers = [10, 20, 30, 40, 50]\n# Base Address = 0x1000, sizeof(int) = 4 bytes\n# numbers[2] is located at 0x1000 + 2 * 4 = 0x1008",
                                "explanation": "Accessing index 2 jumps directly to memory offset 0x1008 without reading preceding slots."
                            }
                        ]
                    }
                },
                {
                    "title": "Array Indexing",
                    "slug": "array-indexing",
                    "content_type": "CONCEPT",
                    "order_index": 2,
                    "estimated_minutes": 8,
                    "content_json": {
                        "concept_text": "Zero-based indexing is standard across modern computing languages. The index represents the offset (distance in element units) from the starting memory address of the array.\n\nThe first element is at offset 0 (Base Address + 0), the second element is at offset 1 (Base Address + 1 * size), and the last element of an N-element array is at offset N - 1.\n\nAttempting to read or write beyond valid indices (e.g., negative indices or indices >= N) causes buffer overflows in unmanaged languages or raises an IndexError exception in managed languages like Python and Dart.",
                        "key_points": [
                            "Index values represent zero-relative distance offsets from the base memory pointer.",
                            "Valid indices strictly range from 0 to N - 1 for an array of length N.",
                            "Off-by-one errors (accessing index N instead of N - 1) are a common source of runtime faults.",
                            "Multi-dimensional indexing maps into 1D memory using the formula: Index = row * total_columns + column."
                        ],
                        "examples": [
                            {
                                "title": "0-Indexed Boundary Calculations",
                                "code": "arr = [42, 99, 13, 77]\nfirst_elem = arr[0]      # Offset 0 -> 42\nlast_elem  = arr[len(arr) - 1] # Offset 3 -> 77",
                                "explanation": "Always verify that array length is greater than 0 before reading index 0 or len - 1."
                            }
                        ]
                    }
                },
                {
                    "title": "Array Traversal",
                    "slug": "array-traversal",
                    "content_type": "VISUALIZATION",
                    "order_index": 3,
                    "estimated_minutes": 15,
                    "content_json": {
                        "algorithm_name": "arrayTraversal",
                        "description": "Array traversal is the foundational process of visiting every single element in the array sequentially from the starting index 0 to the final index n - 1.\n\nDuring traversal, a loop pointer index advances step-by-step, performing operations such as inspection, printing, accumulation, or validation on each item.\n\nBecause every element is visited exactly once, array traversal requires linear O(n) time and O(1) auxiliary space.",
                        "default_input": {"array": [5, 3, 8, 1, 9]},
                        "code_snippet": SNIPPET_ARRAY_TRAVERSAL,
                        "leetcode_ref": None,
                        "complexity": {"time": "O(n)", "space": "O(1)"}
                    }
                },
                {
                    "title": "Updating Elements",
                    "slug": "updating-elements",
                    "content_type": "VISUALIZATION",
                    "order_index": 4,
                    "estimated_minutes": 10,
                    "content_json": {
                        "algorithm_name": "updateElement",
                        "description": "Updating an element modifies the existing value at a given target index without changing the length or overall structure of the array.\n\nBecause the exact memory address is computed in a single step using index arithmetic, the new value is written directly into memory in constant O(1) time.\n\nNo shifting of adjacent elements is required, making updates one of the most efficient operations on arrays.",
                        "default_input": {"array": [10, 20, 30, 40], "index": 2, "value": 99},
                        "code_snippet": SNIPPET_UPDATE_ELEMENT,
                        "leetcode_ref": None,
                        "complexity": {"time": "O(1)", "space": "O(1)"}
                    }
                },
            ],
        },
        # ----------------------------------------------------------------------
        # MODULE 2: Array Operations
        # ----------------------------------------------------------------------
        {
            "title": "Array Operations",
            "order_index": 2,
            "lessons": [
                {
                    "title": "Insert Element (Right Shift)",
                    "slug": "insert-element-right-shift",
                    "content_type": "VISUALIZATION",
                    "order_index": 1,
                    "estimated_minutes": 12,
                    "content_json": {
                        "algorithm_name": "insertElement",
                        "description": "Inserting an element at an arbitrary position inside an array requires creating a vacant slot without overwriting existing data.\n\nTo accomplish this, elements starting from the target index to the end of the array must be shifted one position to the right. The shift must proceed from right to left (backwards) to prevent overwriting values.\n\nIn the worst case (inserting at index 0), all n elements are shifted, resulting in an O(n) time complexity.",
                        "default_input": {"array": [1, 2, 4, 5], "index": 2, "value": 3},
                        "code_snippet": SNIPPET_INSERT_ELEMENT,
                        "leetcode_ref": None,
                        "complexity": {"time": "O(n)", "space": "O(1)"}
                    }
                },
                {
                    "title": "Delete Element (Left Shift)",
                    "slug": "delete-element-left-shift",
                    "content_type": "VISUALIZATION",
                    "order_index": 2,
                    "estimated_minutes": 12,
                    "content_json": {
                        "algorithm_name": "deleteElement",
                        "description": "Deleting an element removes the value at a specified index while preserving the contiguous structure of the array.\n\nAfter removing the target, a gap is left behind. All elements to the right of the target index must be shifted one position to the left (forward) from index to len - 2.\n\nFinally, the trailing duplicate slot is removed, reducing the array size by 1. Deletion requires linear O(n) time in the worst case.",
                        "default_input": {"array": [1, 2, 3, 4, 5], "index": 2},
                        "code_snippet": SNIPPET_DELETE_ELEMENT,
                        "leetcode_ref": None,
                        "complexity": {"time": "O(n)", "space": "O(1)"}
                    }
                },
                {
                    "title": "Linear Search",
                    "slug": "linear-search",
                    "content_type": "VISUALIZATION",
                    "order_index": 3,
                    "estimated_minutes": 10,
                    "content_json": {
                        "algorithm_name": "linearSearch",
                        "description": "Linear Search is the fundamental search algorithm for unsorted arrays. It inspects elements sequentially from left to right, comparing each item against the target query.\n\nIf a match is discovered, the algorithm terminates immediately and returns the 0-based index of the target. If the search reaches the end of the array without finding a match, it returns -1.\n\nLinear search works on both sorted and unsorted sequences with an average and worst-case time complexity of O(n).",
                        "default_input": {"array": [4, 2, 7, 1, 9], "target": 7},
                        "code_snippet": SNIPPET_LINEAR_SEARCH,
                        "leetcode_ref": None,
                        "complexity": {"time": "O(n)", "space": "O(1)"}
                    }
                },
                {
                    "title": "Find Maximum & Minimum",
                    "slug": "find-maximum-minimum",
                    "content_type": "VISUALIZATION",
                    "order_index": 4,
                    "estimated_minutes": 10,
                    "content_json": {
                        "algorithm_names": ["findMaximum", "findMinimum"],
                        "description": "Finding the maximum or minimum value in an unsorted array requires establishing an initial benchmark candidate at index 0 and comparing every subsequent element against this benchmark.\n\nWhenever a scanned element exceeds the current maximum (or is less than the current minimum), the candidate value and its corresponding index are updated.\n\nThis algorithm requires exactly n - 1 comparisons, achieving optimal O(n) time and O(1) auxiliary memory.",
                        "default_input": {"array": [3, 7, 2, 9, 5]},
                        "code_snippets": {
                            "findMaximum": SNIPPET_FIND_MAXIMUM,
                            "findMinimum": SNIPPET_FIND_MINIMUM
                        },
                        "complexity": {"time": "O(n)", "space": "O(1)"}
                    }
                },
            ],
        },
        # ----------------------------------------------------------------------
        # MODULE 3: Array Patterns
        # ----------------------------------------------------------------------
        {
            "title": "Array Patterns",
            "order_index": 3,
            "lessons": [
                {
                    "title": "Reverse Array (Two Pointers)",
                    "slug": "reverse-array-two-pointers",
                    "content_type": "VISUALIZATION",
                    "order_index": 1,
                    "estimated_minutes": 15,
                    "content_json": {
                        "algorithm_name": "reverseArray",
                        "description": "Reversing an array using the two-pointer pattern swaps symmetric pairs of elements from opposite ends of the array toward the center.\n\nThe algorithm initializes `left` at index 0 and `right` at index n - 1. In each cycle, values at `left` and `right` are swapped, `left` increments, and `right` decrements until the pointers meet or cross.\n\nThis operation achieves an in-place reversal in O(n/2) = O(n) time with O(1) memory.",
                        "default_input": {"array": [1, 2, 3, 4, 5]},
                        "code_snippet": SNIPPET_REVERSE_ARRAY,
                        "leetcode_ref": "#344",
                        "complexity": {"time": "O(n)", "space": "O(1)"}
                    }
                },
                {
                    "title": "Two Sum",
                    "slug": "two-sum",
                    "content_type": "VISUALIZATION",
                    "order_index": 2,
                    "estimated_minutes": 20,
                    "content_json": {
                        "algorithm_name": "twoSum",
                        "description": "The Two Sum problem seeks two indices whose corresponding array values add up to a specified target value.\n\nIn the brute-force visualization approach, an outer pointer i scans from 0 to n - 1 while an inner pointer j checks every following element from i + 1 to n - 1. This systematically checks all n*(n-1)/2 unique pairs.\n\nWhen `arr[i] + arr[j] == target`, the matching index pair `[i, j]` is immediately returned.",
                        "default_input": {"array": [3, 2, 4], "target": 6},
                        "code_snippet": SNIPPET_TWO_SUM,
                        "leetcode_ref": "#1",
                        "complexity": {"time": "O(n^2)", "space": "O(1)"}
                    }
                },
                {
                    "title": "Contains Duplicate",
                    "slug": "contains-duplicate",
                    "content_type": "VISUALIZATION",
                    "order_index": 3,
                    "estimated_minutes": 15,
                    "content_json": {
                        "algorithm_name": "containsDuplicate",
                        "description": "The Contains Duplicate algorithm determines if any element appears at least twice in an array.\n\nAs the algorithm steps through the array sequentially, it performs an O(1) lookup against a hash set of previously visited elements (`seen`). If the current item is already present in `seen`, it returns True.\n\nIf the entire array is traversed without a duplicate match, the item is added to `seen` and the algorithm returns False upon termination in linear O(n) time.",
                        "default_input": {"array": [1, 2, 3, 1]},
                        "code_snippet": SNIPPET_CONTAINS_DUPLICATE,
                        "leetcode_ref": "#217",
                        "complexity": {"time": "O(n)", "space": "O(n)"}
                    }
                },
                {
                    "title": "Maximum Subarray — Kadane's Algorithm",
                    "slug": "maximum-subarray-kadanes",
                    "content_type": "VISUALIZATION",
                    "order_index": 4,
                    "estimated_minutes": 20,
                    "content_json": {
                        "algorithm_name": "kadaneMaxSubarray",
                        "description": "Kadane's Algorithm solves the Maximum Contiguous Subarray Sum problem in optimal linear O(n) time using dynamic programming principles.\n\nAt each index i, the algorithm makes a local greedy choice: either append `arr[i]` to the running current subarray (`current + arr[i]`) or discard the past and start a fresh subarray directly at `arr[i]` (`current = arr[i]`).\n\nThe global variable `best` continuously records the highest value achieved by `current` across all steps.",
                        "default_input": {"array": [-2, 1, -3, 4, -1, 2, 1, -5, 4]},
                        "code_snippet": SNIPPET_KADANE,
                        "leetcode_ref": "#53",
                        "complexity": {"time": "O(n)", "space": "O(1)"}
                    }
                },
            ],
        },
        # ----------------------------------------------------------------------
        # MODULE 4: Real Problems
        # ----------------------------------------------------------------------
        {
            "title": "Real Problems",
            "order_index": 4,
            "lessons": [
                {
                    "title": "Best Time to Buy and Sell Stock",
                    "slug": "best-time-to-buy-sell-stock",
                    "content_type": "VISUALIZATION",
                    "order_index": 1,
                    "estimated_minutes": 15,
                    "content_json": {
                        "algorithm_name": "bestTimeToBuySellStock",
                        "description": "Calculates the maximum profit achievable from a single buy and single sell transaction on a chronological price timeline.\n\nThe algorithm scans forward through time, tracking the lowest price encountered so far (`min_price`). At each day i, it calculates the profit if sold today (`prices[i] - min_price`) and updates the global `best` profit.\n\nThis one-pass strategy avoids nested loops, running in O(n) time with O(1) space.",
                        "default_input": {"array": [7, 1, 5, 3, 6, 4]},
                        "code_snippet": SNIPPET_BUY_SELL_STOCK,
                        "leetcode_ref": "#121",
                        "complexity": {"time": "O(n)", "space": "O(1)"}
                    }
                },
                {
                    "title": "Move Zeroes",
                    "slug": "move-zeroes",
                    "content_type": "PROBLEM",
                    "order_index": 2,
                    "estimated_minutes": 15,
                    "content_json": {
                        "problem_statement": "Given an integer array nums, shift all 0 values to the end of the array while maintaining the relative order of the non-zero elements in-place without creating a copy of the array.",
                        "examples": [
                            {
                                "input": "nums = [0, 1, 0, 3, 12]",
                                "output": "[1, 3, 12, 0, 0]",
                                "explanation": "All non-zero elements (1, 3, 12) maintain their relative order, and zeroes are relocated to the end."
                            },
                            {
                                "input": "nums = [0]",
                                "output": "[0]",
                                "explanation": "Single zero element remains at index 0."
                            }
                        ],
                        "constraints": [
                            "1 <= nums.length <= 10^4",
                            "-2^31 <= nums[i] <= 2^31 - 1"
                        ],
                        "leetcode_ref": "#283",
                        "starter_code": "def move_zeroes(nums: list[int]) -> None:\n    \"\"\"Do not return anything, modify nums in-place instead.\"\"\"\n    pass",
                        "hint": "Use a two-pointer write index to collect non-zero elements at the front, then fill remaining slots with zeroes."
                    }
                },
                {
                    "title": "Remove Duplicates",
                    "slug": "remove-duplicates-sorted-array",
                    "content_type": "PROBLEM",
                    "order_index": 3,
                    "estimated_minutes": 15,
                    "content_json": {
                        "problem_statement": "Given an integer array nums sorted in non-decreasing order, remove duplicate elements in-place such that each unique element appears only once. Return the total count of unique elements k.",
                        "examples": [
                            {
                                "input": "nums = [1, 1, 2]",
                                "output": "k = 2, nums = [1, 2, _]",
                                "explanation": "The function returns k = 2, with the first two elements of nums being 1 and 2."
                            },
                            {
                                "input": "nums = [0, 0, 1, 1, 1, 2, 2, 3, 3, 4]",
                                "output": "k = 5, nums = [0, 1, 2, 3, 4, _, _, _, _, _]",
                                "explanation": "The first 5 elements hold unique numbers 0, 1, 2, 3, 4."
                            }
                        ],
                        "constraints": [
                            "1 <= nums.length <= 3 * 10^4",
                            "-100 <= nums[i] <= 100",
                            "nums is sorted in non-decreasing order."
                        ],
                        "leetcode_ref": "#26",
                        "starter_code": "def remove_duplicates(nums: list[int]) -> int:\n    pass",
                        "hint": "Since the array is sorted, duplicate values are adjacent. Use a slow-runner pointer to overwrite duplicates in-place."
                    }
                },
                {
                    "title": "Merge Sorted Array",
                    "slug": "merge-sorted-array",
                    "content_type": "PROBLEM",
                    "order_index": 4,
                    "estimated_minutes": 20,
                    "content_json": {
                        "problem_statement": "You are given two integer arrays nums1 and nums2, sorted in non-decreasing order, and two integers m and n representing the number of valid elements. Merge nums2 into nums1 as one sorted array in-place.",
                        "examples": [
                            {
                                "input": "nums1 = [1, 2, 3, 0, 0, 0], m = 3, nums2 = [2, 5, 6], n = 3",
                                "output": "[1, 2, 2, 3, 5, 6]",
                                "explanation": "The elements being merged are [1, 2, 3] and [2, 5, 6], placed inside nums1 in sorted order."
                            },
                            {
                                "input": "nums1 = [1], m = 1, nums2 = [], n = 0",
                                "output": "[1]",
                                "explanation": "nums2 is empty, so nums1 remains [1]."
                            }
                        ],
                        "constraints": [
                            "nums1.length == m + n",
                            "nums2.length == n",
                            "0 <= m, n <= 200",
                            "-10^9 <= nums1[i], nums2[j] <= 10^9"
                        ],
                        "leetcode_ref": "#88",
                        "starter_code": "def merge(nums1: list[int], m: int, nums2: list[int], n: int) -> None:\n    \"\"\"Do not return anything, modify nums1 in-place instead.\"\"\"\n    pass",
                        "hint": "Start placing elements from the back of nums1 (index m + n - 1) using three pointers to avoid overwriting unprocessed values."
                    }
                },
            ],
        },
    ],
}


# ==============================================================================
# SEED EXECUTION FUNCTION (IDEMPOTENT)
# ==============================================================================

def seed_arrays_course():
    db = SessionLocal()
    try:
        # 1. Check existing courses
        existing_courses = db.query(Course).all()
        print(f"Total existing courses in DB: {len(existing_courses)}")

        # 2. Unpublish other placeholder courses (binary-trees, dynamic-programming)
        for c in existing_courses:
            if c.slug in ["binary-trees", "dynamic-programming"]:
                if c.is_published:
                    c.is_published = False
                    print(f"Unpublished placeholder course: '{c.slug}' (is_published -> False)")

        # 3. Delete existing 'arrays' course to reconcile schema completely
        existing_arrays = db.query(Course).filter(Course.slug == "arrays").first()
        if existing_arrays:
            print(f"Found existing 'arrays' course (ID: {existing_arrays.id}). Deleting for clean rebuild...")
            db.delete(existing_arrays)
            db.commit()
            print("Successfully deleted old 'arrays' course and cascaded relations.")

        # 4. Determine course creator (first available user)
        creator_user = db.query(User).first()
        creator_id = creator_user.id if creator_user else None

        # 5. Create new Arrays course
        course = Course(
            id=uuid.uuid4(),
            title=ARRAYS_COURSE_SPEC["title"],
            slug=ARRAYS_COURSE_SPEC["slug"],
            description=ARRAYS_COURSE_SPEC["description"],
            difficulty=ARRAYS_COURSE_SPEC["difficulty"],
            topic_category=ARRAYS_COURSE_SPEC["topic_category"],
            thumbnail_url=ARRAYS_COURSE_SPEC["thumbnail_url"],
            is_published=ARRAYS_COURSE_SPEC["is_published"],
            created_by=creator_id,
        )
        db.add(course)
        db.flush()

        total_lessons_seeded = 0
        visualization_algo_names = set()

        for mod_spec in ARRAYS_COURSE_SPEC["modules"]:
            module = CourseModule(
                id=uuid.uuid4(),
                course_id=course.id,
                title=mod_spec["title"],
                order_index=mod_spec["order_index"],
            )
            db.add(module)
            db.flush()

            for lesson_spec in mod_spec["lessons"]:
                lesson = Lesson(
                    id=uuid.uuid4(),
                    module_id=module.id,
                    title=lesson_spec["title"],
                    slug=lesson_spec["slug"],
                    content_type=lesson_spec["content_type"],
                    order_index=lesson_spec["order_index"],
                    estimated_minutes=lesson_spec["estimated_minutes"],
                    content_json=lesson_spec["content_json"],
                )
                db.add(lesson)
                total_lessons_seeded += 1

                # Track algorithm names for validation
                cjson = lesson_spec["content_json"]
                if "algorithm_name" in cjson:
                    visualization_algo_names.add(cjson["algorithm_name"])
                if "algorithm_names" in cjson:
                    for name in cjson["algorithm_names"]:
                        visualization_algo_names.add(name)

        db.commit()
        print(f"\nSuccessfully seeded course '{course.title}' ({course.slug}):")
        print(f" - Modules: {len(ARRAYS_COURSE_SPEC['modules'])}")
        print(f" - Lessons: {total_lessons_seeded}")
        print(f" - Unique Algorithm Visualizations: {len(visualization_algo_names)}")
        print(f" - Algorithms: {sorted(list(visualization_algo_names))}")

    except Exception as e:
        db.rollback()
        print(f"Error seeding arrays course: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_arrays_course()
