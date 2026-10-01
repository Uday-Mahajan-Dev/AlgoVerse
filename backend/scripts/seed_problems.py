import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from sqlalchemy import select
from app.db.session import SessionLocal
from app.models.lesson import Lesson
from app.models.problem import Problem
from app.models.test_case import TestCase

PROBLEMS_DATA = [
    {
        "lesson_slug": "move-zeroes",
        "title": "Move Zeroes",
        "function_name": "move_zeroes",
        "description": (
            "Given an integer array `nums`, move all `0`'s to the end of it while "
            "maintaining the relative order of the non-zero elements.\n\n"
            "**Note:** You must do this in-place without making a copy of the array.\n\n"
            "### Example 1:\n"
            "```\n"
            "Input: nums = [0, 1, 0, 3, 12]\n"
            "Output: [1, 3, 12, 0, 0]\n"
            "```\n\n"
            "### Example 2:\n"
            "```\n"
            "Input: nums = [0]\n"
            "Output: [0]\n"
            "```\n\n"
            "### Constraints:\n"
            "- `1 <= nums.length <= 10^4`\n"
            "- `-2^31 <= nums[i] <= 2^31 - 1`\n\n"
            "**Follow up:** Could you minimize the total number of operations done?"
        ),
        "starter_code_python": (
            "def move_zeroes(nums: list[int]) -> None:\n"
            "    \"\"\"\n"
            "    Do not return anything, modify nums in-place instead.\n"
            "    \"\"\"\n"
            "    # Write your solution below\n"
            "    pass\n\n"
            "if __name__ == '__main__':\n"
            "    import sys\n"
            "    lines = sys.stdin.read().split()\n"
            "    if lines:\n"
            "        n = int(lines[0])\n"
            "        nums = [int(x) for x in lines[1:n+1]]\n"
            "        move_zeroes(nums)\n"
            "        print(*(nums))\n"
        ),
        "starter_code_java": (
            "import java.util.Scanner;\n\n"
            "public class Main {\n"
            "    public static void moveZeroes(int[] nums) {\n"
            "        // Write your solution below\n"
            "    }\n\n"
            "    public static void main(String[] args) {\n"
            "        Scanner sc = new Scanner(System.in);\n"
            "        if (!sc.hasNextInt()) return;\n"
            "        int n = sc.nextInt();\n"
            "        int[] nums = new int[n];\n"
            "        for (int i = 0; i < n; i++) nums[i] = sc.nextInt();\n"
            "        moveZeroes(nums);\n"
            "        for (int i = 0; i < n; i++) {\n"
            "            System.out.print(nums[i] + (i < n - 1 ? \" \" : \"\"));\n"
            "        }\n"
            "        System.out.println();\n"
            "    }\n"
            "}\n"
        ),
        "starter_code_cpp": (
            "#include <iostream>\n"
            "#include <vector>\n"
            "using namespace std;\n\n"
            "void moveZeroes(vector<int>& nums) {\n"
            "    // Write your solution below\n"
            "}\n\n"
            "int main() {\n"
            "    int n;\n"
            "    if (cin >> n) {\n"
            "        vector<int> nums(n);\n"
            "        for (int i = 0; i < n; ++i) cin >> nums[i];\n"
            "        moveZeroes(nums);\n"
            "        for (int i = 0; i < n; ++i) {\n"
            "            cout << nums[i] << (i < n - 1 ? \" \" : \"\");\n"
            "        }\n"
            "        cout << \"\\n\";\n"
            "    }\n"
            "    return 0;\n"
            "}\n"
        ),
        "solution_code_python": (
            "def move_zeroes(nums: list[int]) -> None:\n"
            "    insert_pos = 0\n"
            "    for i in range(len(nums)):\n"
            "        if nums[i] != 0:\n"
            "            nums[insert_pos], nums[i] = nums[i], nums[insert_pos]\n"
            "            insert_pos += 1\n\n"
            "if __name__ == '__main__':\n"
            "    import sys\n"
            "    lines = sys.stdin.read().split()\n"
            "    if lines:\n"
            "        n = int(lines[0])\n"
            "        nums = [int(x) for x in lines[1:n+1]]\n"
            "        move_zeroes(nums)\n"
            "        print(*(nums))\n"
        ),
        "solution_code_java": (
            "import java.util.Scanner;\n\n"
            "public class Main {\n"
            "    public static void moveZeroes(int[] nums) {\n"
            "        int insertPos = 0;\n"
            "        for (int i = 0; i < nums.length; i++) {\n"
            "            if (nums[i] != 0) {\n"
            "                int tmp = nums[insertPos];\n"
            "                nums[insertPos] = nums[i];\n"
            "                nums[i] = tmp;\n"
            "                insertPos++;\n"
            "            }\n"
            "        }\n"
            "    }\n\n"
            "    public static void main(String[] args) {\n"
            "        Scanner sc = new Scanner(System.in);\n"
            "        if (!sc.hasNextInt()) return;\n"
            "        int n = sc.nextInt();\n"
            "        int[] nums = new int[n];\n"
            "        for (int i = 0; i < n; i++) nums[i] = sc.nextInt();\n"
            "        moveZeroes(nums);\n"
            "        for (int i = 0; i < n; i++) {\n"
            "            System.out.print(nums[i] + (i < n - 1 ? \" \" : \"\"));\n"
            "        }\n"
            "        System.out.println();\n"
            "    }\n"
            "}\n"
        ),
        "solution_code_cpp": (
            "#include <iostream>\n"
            "#include <vector>\n"
            "using namespace std;\n\n"
            "void moveZeroes(vector<int>& nums) {\n"
            "    int insert_pos = 0;\n"
            "    for (int i = 0; i < (int)nums.size(); ++i) {\n"
            "        if (nums[i] != 0) {\n"
            "            swap(nums[insert_pos], nums[i]);\n"
            "            insert_pos++;\n"
            "        }\n"
            "    }\n"
            "}\n\n"
            "int main() {\n"
            "    int n;\n"
            "    if (cin >> n) {\n"
            "        vector<int> nums(n);\n"
            "        for (int i = 0; i < n; ++i) cin >> nums[i];\n"
            "        moveZeroes(nums);\n"
            "        for (int i = 0; i < n; ++i) {\n"
            "            cout << nums[i] << (i < n - 1 ? \" \" : \"\");\n"
            "        }\n"
            "        cout << \"\\n\";\n"
            "    }\n"
            "    return 0;\n"
            "}\n"
        ),
        "test_cases": [
            {"stdin": "5\n0 1 0 3 12", "stdout": "1 3 12 0 0", "is_hidden": False, "order": 1},
            {"stdin": "1\n0", "stdout": "0", "is_hidden": False, "order": 2},
            {"stdin": "3\n1 2 3", "stdout": "1 2 3", "is_hidden": True, "order": 3},
            {"stdin": "4\n0 0 0 1", "stdout": "1 0 0 0", "is_hidden": True, "order": 4},
        ],
    },
    {
        "lesson_slug": "remove-duplicates-sorted-array",
        "title": "Remove Duplicates from Sorted Array",
        "function_name": "remove_duplicates",
        "description": (
            "Given an integer array `nums` sorted in **non-decreasing order**, remove the "
            "duplicates **in-place** such that each unique element appears only **once**.\n\n"
            "The relative order of the elements should be kept the same.\n\n"
            "Return `k` after placing the final result in the first `k` slots of `nums`.\n\n"
            "### Example 1:\n"
            "```\n"
            "Input: nums = [1, 1, 2]\n"
            "Output: 2, nums = [1, 2, _]\n"
            "```\n\n"
            "### Example 2:\n"
            "```\n"
            "Input: nums = [0, 0, 1, 1, 1, 2, 2, 3, 3, 4]\n"
            "Output: 5, nums = [0, 1, 2, 3, 4, _, _, _, _, _]\n"
            "```\n\n"
            "### Constraints:\n"
            "- `1 <= nums.length <= 3 * 10^4`\n"
            "- `-100 <= nums[i] <= 100`\n"
            "- `nums` is sorted in non-decreasing order."
        ),
        "starter_code_python": (
            "def remove_duplicates(nums: list[int]) -> int:\n"
            "    \"\"\"\n"
            "    Remove duplicates in-place and return number of unique elements k.\n"
            "    \"\"\"\n"
            "    # Write your solution below\n"
            "    return 0\n\n"
            "if __name__ == '__main__':\n"
            "    import sys\n"
            "    lines = sys.stdin.read().split()\n"
            "    if lines:\n"
            "        n = int(lines[0])\n"
            "        nums = [int(x) for x in lines[1:n+1]]\n"
            "        k = remove_duplicates(nums)\n"
            "        print(k)\n"
        ),
        "starter_code_java": (
            "import java.util.Scanner;\n\n"
            "public class Main {\n"
            "    public static int removeDuplicates(int[] nums) {\n"
            "        // Write your solution below\n"
            "        return 0;\n"
            "    }\n\n"
            "    public static void main(String[] args) {\n"
            "        Scanner sc = new Scanner(System.in);\n"
            "        if (!sc.hasNextInt()) return;\n"
            "        int n = sc.nextInt();\n"
            "        int[] nums = new int[n];\n"
            "        for (int i = 0; i < n; i++) nums[i] = sc.nextInt();\n"
            "        int k = removeDuplicates(nums);\n"
            "        System.out.println(k);\n"
            "    }\n"
            "}\n"
        ),
        "starter_code_cpp": (
            "#include <iostream>\n"
            "#include <vector>\n"
            "using namespace std;\n\n"
            "int removeDuplicates(vector<int>& nums) {\n"
            "    // Write your solution below\n"
            "    return 0;\n"
            "}\n\n"
            "int main() {\n"
            "    int n;\n"
            "    if (cin >> n) {\n"
            "        vector<int> nums(n);\n"
            "        for (int i = 0; i < n; ++i) cin >> nums[i];\n"
            "        int k = removeDuplicates(nums);\n"
            "        cout << k << \"\\n\";\n"
            "    }\n"
            "    return 0;\n"
            "}\n"
        ),
        "solution_code_python": (
            "def remove_duplicates(nums: list[int]) -> int:\n"
            "    if not nums:\n"
            "        return 0\n"
            "    k = 1\n"
            "    for i in range(1, len(nums)):\n"
            "        if nums[i] != nums[i - 1]:\n"
            "            nums[k] = nums[i]\n"
            "            k += 1\n"
            "    return k\n\n"
            "if __name__ == '__main__':\n"
            "    import sys\n"
            "    lines = sys.stdin.read().split()\n"
            "    if lines:\n"
            "        n = int(lines[0])\n"
            "        nums = [int(x) for x in lines[1:n+1]]\n"
            "        k = remove_duplicates(nums)\n"
            "        print(k)\n"
        ),
        "solution_code_java": (
            "import java.util.Scanner;\n\n"
            "public class Main {\n"
            "    public static int removeDuplicates(int[] nums) {\n"
            "        if (nums == null || nums.length == 0) return 0;\n"
            "        int k = 1;\n"
            "        for (int i = 1; i < nums.length; i++) {\n"
            "            if (nums[i] != nums[i - 1]) {\n"
            "                nums[k++] = nums[i];\n"
            "            }\n"
            "        }\n"
            "        return k;\n"
            "    }\n\n"
            "    public static void main(String[] args) {\n"
            "        Scanner sc = new Scanner(System.in);\n"
            "        if (!sc.hasNextInt()) return;\n"
            "        int n = sc.nextInt();\n"
            "        int[] nums = new int[n];\n"
            "        for (int i = 0; i < n; i++) nums[i] = sc.nextInt();\n"
            "        int k = removeDuplicates(nums);\n"
            "        System.out.println(k);\n"
            "    }\n"
            "}\n"
        ),
        "solution_code_cpp": (
            "#include <iostream>\n"
            "#include <vector>\n"
            "using namespace std;\n\n"
            "int removeDuplicates(vector<int>& nums) {\n"
            "    if (nums.empty()) return 0;\n"
            "    int k = 1;\n"
            "    for (int i = 1; i < (int)nums.size(); ++i) {\n"
            "        if (nums[i] != nums[i - 1]) {\n"
            "            nums[k++] = nums[i];\n"
            "        }\n"
            "    }\n"
            "    return k;\n"
            "}\n\n"
            "int main() {\n"
            "    int n;\n"
            "    if (cin >> n) {\n"
            "        vector<int> nums(n);\n"
            "        for (int i = 0; i < n; ++i) cin >> nums[i];\n"
            "        int k = removeDuplicates(nums);\n"
            "        cout << k << \"\\n\";\n"
            "    }\n"
            "    return 0;\n"
            "}\n"
        ),
        "test_cases": [
            {"stdin": "3\n1 1 2", "stdout": "2", "is_hidden": False, "order": 1},
            {"stdin": "10\n0 0 1 1 1 2 2 3 3 4", "stdout": "5", "is_hidden": False, "order": 2},
            {"stdin": "1\n1", "stdout": "1", "is_hidden": True, "order": 3},
            {"stdin": "4\n1 1 1 1", "stdout": "1", "is_hidden": True, "order": 4},
        ],
    },
    {
        "lesson_slug": "merge-sorted-array",
        "title": "Merge Sorted Array",
        "function_name": "merge",
        "description": (
            "You are given two integer arrays `nums1` and `nums2`, sorted in **non-decreasing order**, "
            "and two integers `m` and `n`, representing the number of elements in `nums1` and `nums2` respectively.\n\n"
            "**Merge** `nums1` and `nums2` into a single array sorted in non-decreasing order.\n\n"
            "The final sorted array should not be returned by the function, but instead be stored inside the array `nums1`. "
            "To accommodate this, `nums1` has a length of `m + n`, where the first `m` elements denote the elements that should be merged, "
            "and the last `n` elements are set to `0` and should be ignored.\n\n"
            "### Example 1:\n"
            "```\n"
            "Input: nums1 = [1,2,3,0,0,0], m = 3, nums2 = [2,5,6], n = 3\n"
            "Output: [1,2,2,3,5,6]\n"
            "```\n\n"
            "### Example 2:\n"
            "```\n"
            "Input: nums1 = [1], m = 1, nums2 = [], n = 0\n"
            "Output: [1]\n"
            "```\n\n"
            "### Constraints:\n"
            "- `nums1.length == m + n`\n"
            "- `nums2.length == n`\n"
            "- `0 <= m, n <= 200`\n"
            "- `1 <= m + n <= 200`\n"
            "- `-10^9 <= nums1[i], nums2[j] <= 10^9`"
        ),
        "starter_code_python": (
            "def merge(nums1: list[int], m: int, nums2: list[int], n: int) -> None:\n"
            "    \"\"\"\n"
            "    Do not return anything, modify nums1 in-place instead.\n"
            "    \"\"\"\n"
            "    # Write your solution below\n"
            "    pass\n\n"
            "if __name__ == '__main__':\n"
            "    import sys\n"
            "    tokens = sys.stdin.read().split()\n"
            "    if tokens:\n"
            "        idx = 0\n"
            "        m = int(tokens[idx]); idx += 1\n"
            "        nums1_elems = [int(x) for x in tokens[idx:idx+m]]; idx += m\n"
            "        n = int(tokens[idx]); idx += 1\n"
            "        nums2 = [int(x) for x in tokens[idx:idx+n]]; idx += n\n"
            "        total_len = int(tokens[idx]) if idx < len(tokens) else (m + n)\n"
            "        nums1 = nums1_elems + [0] * n\n"
            "        merge(nums1, m, nums2, n)\n"
            "        print(*(nums1))\n"
        ),
        "starter_code_java": (
            "import java.util.Scanner;\n\n"
            "public class Main {\n"
            "    public static void merge(int[] nums1, int m, int[] nums2, int n) {\n"
            "        // Write your solution below\n"
            "    }\n\n"
            "    public static void main(String[] args) {\n"
            "        Scanner sc = new Scanner(System.in);\n"
            "        if (!sc.hasNextInt()) return;\n"
            "        int m = sc.nextInt();\n"
            "        int[] nums1_elems = new int[m];\n"
            "        for (int i = 0; i < m; i++) nums1_elems[i] = sc.nextInt();\n"
            "        int n = sc.nextInt();\n"
            "        int[] nums2 = new int[n];\n"
            "        for (int i = 0; i < n; i++) nums2[i] = sc.nextInt();\n"
            "        if (sc.hasNextInt()) sc.nextInt();\n"
            "        int[] nums1 = new int[m + n];\n"
            "        for (int i = 0; i < m; i++) nums1[i] = nums1_elems[i];\n"
            "        merge(nums1, m, nums2, n);\n"
            "        for (int i = 0; i < m + n; i++) {\n"
            "            System.out.print(nums1[i] + (i < m + n - 1 ? \" \" : \"\"));\n"
            "        }\n"
            "        System.out.println();\n"
            "    }\n"
            "}\n"
        ),
        "starter_code_cpp": (
            "#include <iostream>\n"
            "#include <vector>\n"
            "using namespace std;\n\n"
            "void merge(vector<int>& nums1, int m, vector<int>& nums2, int n) {\n"
            "    // Write your solution below\n"
            "}\n\n"
            "int main() {\n"
            "    int m;\n"
            "    if (cin >> m) {\n"
            "        vector<int> nums1_elems(m);\n"
            "        for (int i = 0; i < m; ++i) cin >> nums1_elems[i];\n"
            "        int n;\n"
            "        cin >> n;\n"
            "        vector<int> nums2(n);\n"
            "        for (int i = 0; i < n; ++i) cin >> nums2[i];\n"
            "        int total;\n"
            "        if (cin >> total) {}\n"
            "        vector<int> nums1(m + n, 0);\n"
            "        for (int i = 0; i < m; ++i) nums1[i] = nums1_elems[i];\n"
            "        merge(nums1, m, nums2, n);\n"
            "        for (int i = 0; i < m + n; ++i) {\n"
            "            cout << nums1[i] << (i < m + n - 1 ? \" \" : \"\");\n"
            "        }\n"
            "        cout << \"\\n\";\n"
            "    }\n"
            "    return 0;\n"
            "}\n"
        ),
        "solution_code_python": (
            "def merge(nums1: list[int], m: int, nums2: list[int], n: int) -> None:\n"
            "    p1 = m - 1\n"
            "    p2 = n - 1\n"
            "    p = m + n - 1\n"
            "    while p1 >= 0 and p2 >= 0:\n"
            "        if nums1[p1] > nums2[p2]:\n"
            "            nums1[p] = nums1[p1]\n"
            "            p1 -= 1\n"
            "        else:\n"
            "            nums1[p] = nums2[p2]\n"
            "            p2 -= 1\n"
            "        p -= 1\n"
            "    while p2 >= 0:\n"
            "        nums1[p] = nums2[p2]\n"
            "        p2 -= 1\n"
            "        p -= 1\n\n"
            "if __name__ == '__main__':\n"
            "    import sys\n"
            "    tokens = sys.stdin.read().split()\n"
            "    if tokens:\n"
            "        idx = 0\n"
            "        m = int(tokens[idx]); idx += 1\n"
            "        nums1_elems = [int(x) for x in tokens[idx:idx+m]]; idx += m\n"
            "        n = int(tokens[idx]); idx += 1\n"
            "        nums2 = [int(x) for x in tokens[idx:idx+n]]; idx += n\n"
            "        total_len = int(tokens[idx]) if idx < len(tokens) else (m + n)\n"
            "        nums1 = nums1_elems + [0] * n\n"
            "        merge(nums1, m, nums2, n)\n"
            "        print(*(nums1))\n"
        ),
        "solution_code_java": (
            "import java.util.Scanner;\n\n"
            "public class Main {\n"
            "    public static void merge(int[] nums1, int m, int[] nums2, int n) {\n"
            "        int p1 = m - 1;\n"
            "        int p2 = n - 1;\n"
            "        int p = m + n - 1;\n"
            "        while (p1 >= 0 && p2 >= 0) {\n"
            "            if (nums1[p1] > nums2[p2]) {\n"
            "                nums1[p--] = nums1[p1--];\n"
            "            } else {\n"
            "                nums1[p--] = nums2[p2--];\n"
            "            }\n"
            "        }\n"
            "        while (p2 >= 0) {\n"
            "            nums1[p--] = nums2[p2--];\n"
            "        }\n"
            "    }\n\n"
            "    public static void main(String[] args) {\n"
            "        Scanner sc = new Scanner(System.in);\n"
            "        if (!sc.hasNextInt()) return;\n"
            "        int m = sc.nextInt();\n"
            "        int[] nums1_elems = new int[m];\n"
            "        for (int i = 0; i < m; i++) nums1_elems[i] = sc.nextInt();\n"
            "        int n = sc.nextInt();\n"
            "        int[] nums2 = new int[n];\n"
            "        for (int i = 0; i < n; i++) nums2[i] = sc.nextInt();\n"
            "        if (sc.hasNextInt()) sc.nextInt();\n"
            "        int[] nums1 = new int[m + n];\n"
            "        for (int i = 0; i < m; i++) nums1[i] = nums1_elems[i];\n"
            "        merge(nums1, m, nums2, n);\n"
            "        for (int i = 0; i < m + n; i++) {\n"
            "            System.out.print(nums1[i] + (i < m + n - 1 ? \" \" : \"\"));\n"
            "        }\n"
            "        System.out.println();\n"
            "    }\n"
            "}\n"
        ),
        "solution_code_cpp": (
            "#include <iostream>\n"
            "#include <vector>\n"
            "using namespace std;\n\n"
            "void merge(vector<int>& nums1, int m, vector<int>& nums2, int n) {\n"
            "    int p1 = m - 1;\n"
            "    int p2 = n - 1;\n"
            "    int p = m + n - 1;\n"
            "    while (p1 >= 0 && p2 >= 0) {\n"
            "        if (nums1[p1] > nums2[p2]) {\n"
            "            nums1[p--] = nums1[p1--];\n"
            "        } else {\n"
            "            nums1[p--] = nums2[p2--];\n"
            "        }\n"
            "    }\n"
            "    while (p2 >= 0) {\n"
            "        nums1[p--] = nums2[p2--];\n"
            "    }\n"
            "}\n\n"
            "int main() {\n"
            "    int m;\n"
            "    if (cin >> m) {\n"
            "        vector<int> nums1_elems(m);\n"
            "        for (int i = 0; i < m; ++i) cin >> nums1_elems[i];\n"
            "        int n;\n"
            "        cin >> n;\n"
            "        vector<int> nums2(n);\n"
            "        for (int i = 0; i < n; ++i) cin >> nums2[i];\n"
            "        int total;\n"
            "        if (cin >> total) {}\n"
            "        vector<int> nums1(m + n, 0);\n"
            "        for (int i = 0; i < m; ++i) nums1[i] = nums1_elems[i];\n"
            "        merge(nums1, m, nums2, n);\n"
            "        for (int i = 0; i < m + n; ++i) {\n"
            "            cout << nums1[i] << (i < m + n - 1 ? \" \" : \"\");\n"
            "        }\n"
            "        cout << \"\\n\";\n"
            "    }\n"
            "    return 0;\n"
            "}\n"
        ),
        "test_cases": [
            {"stdin": "3\n1 2 3\n3\n2 5 6\n6", "stdout": "1 2 2 3 5 6", "is_hidden": False, "order": 1},
            {"stdin": "1\n1\n0\n0\n1", "stdout": "1", "is_hidden": False, "order": 2},
            {"stdin": "0\n0\n1\n1\n1", "stdout": "1", "is_hidden": True, "order": 3},
            {"stdin": "3\n4 5 6\n3\n1 2 3\n6", "stdout": "1 2 3 4 5 6", "is_hidden": True, "order": 4},
        ],
    },
]


def seed_problems():
    db = SessionLocal()
    try:
        print("[SEED] Seeding interactive coding practice problems and test cases...")

        for data in PROBLEMS_DATA:
            lesson_slug = data["lesson_slug"]
            lesson = db.execute(select(Lesson).where(Lesson.slug == lesson_slug)).scalars().first()

            if not lesson:
                print(f"  [WARN] Lesson '{lesson_slug}' not found! Skipping problem seed.")
                continue

            # Remove existing problem if present
            existing_problem = db.execute(
                select(Problem).where(Problem.lesson_id == lesson.id)
            ).scalars().first()

            if existing_problem:
                db.delete(existing_problem)
                db.commit()

            problem = Problem(
                lesson_id=lesson.id,
                title=data["title"],
                description=data["description"],
                function_name=data["function_name"],
                starter_code_python=data["starter_code_python"],
                starter_code_java=data["starter_code_java"],
                starter_code_cpp=data["starter_code_cpp"],
                solution_code_python=data["solution_code_python"],
                solution_code_java=data["solution_code_java"],
                solution_code_cpp=data["solution_code_cpp"],
                time_limit_ms=2000,
                memory_limit_mb=64,
            )
            db.add(problem)
            db.commit()
            db.refresh(problem)

            for tc in data["test_cases"]:
                test_case = TestCase(
                    problem_id=problem.id,
                    stdin_input=tc["stdin"],
                    expected_stdout=tc["stdout"],
                    is_hidden=tc["is_hidden"],
                    order_index=tc["order"],
                )
                db.add(test_case)

            db.commit()
            print(f"  [OK] Seeded problem: '{problem.title}' with {len(data['test_cases'])} test cases.")

        print("[DONE] All problems and test cases seeded successfully!")
    finally:
        db.close()


if __name__ == "__main__":
    seed_problems()
