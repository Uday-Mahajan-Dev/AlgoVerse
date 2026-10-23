import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent))

from app.db.session import SessionLocal
from app.models.lesson import Lesson

SNIPPETS_BY_SLUG = {
    "array-traversal": {
        "python": "def traverse(arr):\n    for i in range(len(arr)):\n        visit(arr[i])",
        "java": "public void traverse(int[] arr) {\n    for (int i = 0; i < arr.length; i++) {\n        visit(arr[i]);\n    }\n}",
        "cpp": "void traverse(vector<int>& arr) {\n    for (int i = 0; i < arr.size(); i++) {\n        visit(arr[i]);\n    }\n}",
    },
    "updating-elements": {
        "python": "def update(arr, index, value):\n    if 0 <= index < len(arr):\n        arr[index] = value\n    return arr",
        "java": "public int[] update(int[] arr, int index, int value) {\n    if (index >= 0 && index < arr.length) {\n        arr[index] = value;\n    }\n    return arr;\n}",
        "cpp": "vector<int>& update(vector<int>& arr, int index, int value) {\n    if (index >= 0 && index < arr.size()) {\n        arr[index] = value;\n    }\n    return arr;\n}",
    },
    "insert-element-right-shift": {
        "python": "def insert(arr, index, value):\n    arr.append(None)\n    for i in range(len(arr) - 1, index, -1):\n        arr[i] = arr[i - 1]\n    arr[index] = value\n    return arr",
        "java": "public void insert(int[] arr, int index, int value) {\n    for (int i = arr.length - 1; i > index; i--) {\n        arr[i] = arr[i - 1];\n    }\n    arr[index] = value;\n}",
        "cpp": "void insert(vector<int>& arr, int index, int value) {\n    arr.push_back(0);\n    for (int i = arr.size() - 1; i > index; i--) {\n        arr[i] = arr[i - 1];\n    }\n    arr[index] = value;\n}",
    },
    "delete-element-left-shift": {
        "python": "def delete(arr, index):\n    for i in range(index, len(arr) - 1):\n        arr[i] = arr[i + 1]\n    arr.pop()\n    return arr",
        "java": "public void delete(int[] arr, int index) {\n    for (int i = index; i < arr.length - 1; i++) {\n        arr[i] = arr[i + 1];\n    }\n}",
        "cpp": "void deleteElement(vector<int>& arr, int index) {\n    for (int i = index; i < arr.size() - 1; i++) {\n        arr[i] = arr[i + 1];\n    }\n    arr.pop_back();\n}",
    },
    "linear-search": {
        "python": "def linear_search(arr, target):\n    for i in range(len(arr)):\n        if arr[i] == target:\n            return i\n    return -1",
        "java": "public int linearSearch(int[] arr, int target) {\n    for (int i = 0; i < arr.length; i++) {\n        if (arr[i] == target) return i;\n    }\n    return -1;\n}",
        "cpp": "int linearSearch(vector<int>& arr, int target) {\n    for (int i = 0; i < arr.size(); i++) {\n        if (arr[i] == target) return i;\n    }\n    return -1;\n}",
    },
    "find-maximum-minimum": {
        "python": "def find_max(arr):\n    max_val = arr[0]\n    for i in range(1, len(arr)):\n        if arr[i] > max_val:\n            max_val = arr[i]\n    return max_val",
        "java": "public int findMax(int[] arr) {\n    int maxVal = arr[0];\n    for (int i = 1; i < arr.length; i++) {\n        if (arr[i] > maxVal) maxVal = arr[i];\n    }\n    return maxVal;\n}",
        "cpp": "int findMax(vector<int>& arr) {\n    int maxVal = arr[0];\n    for (int i = 1; i < arr.size(); i++) {\n        if (arr[i] > maxVal) maxVal = arr[i];\n    }\n    return maxVal;\n}",
    },
    "reverse-array-two-pointers": {
        "python": "def reverse_array(arr):\n    left, right = 0, len(arr) - 1\n    while left < right:\n        arr[left], arr[right] = arr[right], arr[left]\n        left += 1\n        right -= 1\n    return arr",
        "java": "public void reverseArray(int[] arr) {\n    int left = 0, right = arr.length - 1;\n    while (left < right) {\n        int temp = arr[left];\n        arr[left] = arr[right];\n        arr[right] = temp;\n        left++; right--;\n    }\n}",
        "cpp": "void reverseArray(vector<int>& arr) {\n    int left = 0, right = arr.size() - 1;\n    while (left < right) {\n        swap(arr[left], arr[right]);\n        left++; right--;\n    }\n}",
    },
    "two-sum": {
        "python": "def two_sum(arr, target):\n    seen = {}\n    for i, num in enumerate(arr):\n        diff = target - num\n        if diff in seen:\n            return [seen[diff], i]\n        seen[num] = i\n    return []",
        "java": "public int[] twoSum(int[] arr, int target) {\n    Map<Integer, Integer> map = new HashMap<>();\n    for (int i = 0; i < arr.length; i++) {\n        int diff = target - arr[i];\n        if (map.containsKey(diff)) return new int[]{map.get(diff), i};\n        map.put(arr[i], i);\n    }\n    return new int[]{};\n}",
        "cpp": "vector<int> twoSum(vector<int>& arr, int target) {\n    unordered_map<int, int> seen;\n    for (int i = 0; i < arr.size(); i++) {\n        int diff = target - arr[i];\n        if (seen.count(diff)) return {seen[diff], i};\n        seen[arr[i]] = i;\n    }\n    return {};\n}",
    },
    "contains-duplicate": {
        "python": "def contains_duplicate(arr):\n    seen = set()\n    for num in arr:\n        if num in seen:\n            return True\n        seen.add(num)\n    return False",
        "java": "public boolean containsDuplicate(int[] arr) {\n    Set<Integer> set = new HashSet<>();\n    for (int num : arr) {\n        if (!set.add(num)) return true;\n    }\n    return false;\n}",
        "cpp": "bool containsDuplicate(vector<int>& arr) {\n    unordered_set<int> seen;\n    for (int num : arr) {\n        if (seen.count(num)) return true;\n        seen.insert(num);\n    }\n    return false;\n}",
    },
    "maximum-subarray-kadanes": {
        "python": "def max_sub_array(nums):\n    max_sum = curr_sum = nums[0]\n    for num in nums[1:]:\n        curr_sum = max(num, curr_sum + num)\n        max_sum = max(max_sum, curr_sum)\n    return max_sum",
        "java": "public int maxSubArray(int[] nums) {\n    int maxSum = nums[0], currSum = nums[0];\n    for (int i = 1; i < nums.length; i++) {\n        currSum = Math.max(nums[i], currSum + nums[i]);\n        maxSum = Math.max(maxSum, currSum);\n    }\n    return maxSum;\n}",
        "cpp": "int maxSubArray(vector<int>& nums) {\n    int maxSum = nums[0], currSum = nums[0];\n    for (int i = 1; i < nums.size(); i++) {\n        currSum = max(nums[i], currSum + nums[i]);\n        maxSum = max(maxSum, currSum);\n    }\n    return maxSum;\n}",
    },
    "best-time-to-buy-sell-stock": {
        "python": "def max_profit(prices):\n    min_price = float('inf')\n    max_profit = 0\n    for price in prices:\n        min_price = min(min_price, price)\n        max_profit = max(max_profit, price - min_price)\n    return max_profit",
        "java": "public int maxProfit(int[] prices) {\n    int minPrice = Integer.MAX_VALUE, maxProfit = 0;\n    for (int price : prices) {\n        minPrice = Math.min(minPrice, price);\n        maxProfit = Math.max(maxProfit, price - minPrice);\n    }\n    return maxProfit;\n}",
        "cpp": "int maxProfit(vector<int>& prices) {\n    int minPrice = INT_MAX, maxProfit = 0;\n    for (int price : prices) {\n        minPrice = min(minPrice, price);\n        maxProfit = max(maxProfit, price - minPrice);\n    }\n    return maxProfit;\n}",
    },
}

def populate():
    db = SessionLocal()
    try:
        lessons = db.query(Lesson).filter(Lesson.content_type == "VISUALIZATION").all()
        updated_count = 0
        for l in lessons:
            content = dict(l.content_json or {})
            slug = l.slug
            if slug in SNIPPETS_BY_SLUG:
                content["code_snippets"] = SNIPPETS_BY_SLUG[slug]
                content["default_language"] = "python"
                l.content_json = content
                updated_count += 1
            elif "code_snippets" in content and isinstance(content["code_snippets"], dict):
                # Ensure python, java, cpp exist
                snips = content["code_snippets"]
                if "python" in snips and ("java" not in snips or "cpp" not in snips):
                    py_code = snips["python"]
                    snips.setdefault("java", f"// Java equivalent\n{py_code}")
                    snips.setdefault("cpp", f"// C++ equivalent\n{py_code}")
                    content["code_snippets"] = snips
                    content["default_language"] = "python"
                    l.content_json = content
                    updated_count += 1
        db.commit()
        print(f"Successfully populated snippets for {updated_count} visualization lessons.")
    finally:
        db.close()

if __name__ == "__main__":
    populate()
