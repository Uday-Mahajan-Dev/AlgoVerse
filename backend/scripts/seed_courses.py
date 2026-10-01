import uuid
from app.db.session import SessionLocal
from app.models.course import Course
from app.models.course_module import CourseModule
from app.models.lesson import Lesson
from app.models.user import User


def seed_courses():
    db = SessionLocal()
    try:
        existing = db.query(Course).first()
        if existing:
            print("Courses already exist in the database. Skipping seed.")
            return

        # Find an admin or teacher or any user to set as creator
        admin_user = db.query(User).first()
        creator_id = admin_user.id if admin_user else None

        # Course 1: Arrays & Dynamic Arrays
        course_arrays = Course(
            id=uuid.uuid4(),
            title="Arrays & Two Pointers",
            slug="arrays",
            description="Master fundamental memory layouts, sliding window mechanics, two-pointer strategies, and in-place manipulations with real-time visual step execution.",
            thumbnail_url="https://images.unsplash.com/photo-1516116211227-bbc13f17316a?w=800&auto=format&fit=crop&q=80",
            difficulty="BEGINNER",
            topic_category="Data Structures",
            is_published=True,
            created_by=creator_id,
        )
        db.add(course_arrays)
        db.flush()

        # Module 1.1: Core Fundamentals
        m1 = CourseModule(
            id=uuid.uuid4(),
            course_id=course_arrays.id,
            title="Module 1: Array Mechanics & Memory Representation",
            order_index=1,
        )
        db.add(m1)
        db.flush()

        l1_1 = Lesson(
            id=uuid.uuid4(),
            module_id=m1.id,
            title="Introduction to Contiguous Memory & Static Arrays",
            slug="arrays-intro-contiguous-memory",
            content_type="CONCEPT",
            order_index=1,
            estimated_minutes=10,
            content_json={
                "overview": "Arrays store elements in contiguous memory locations. Because each element has a fixed size, calculating the memory address of element at index i takes O(1) time.",
                "key_points": [
                    "Contiguous memory layout allows constant time O(1) random access: Base Address + i * sizeof(T).",
                    "Static arrays have fixed capacity set at initialization.",
                    "Dynamic arrays (like std::vector or ArrayList) geometric resizing gives amortized O(1) insertion."
                ],
                "code_example": "int arr[5] = {10, 20, 30, 40, 50};\nint val = arr[2]; // Accessing arr[2] takes O(1) time.",
                "complexity": {
                    "access": "O(1)",
                    "search": "O(N)",
                    "insertion": "O(N) [O(1) at end amortized]",
                    "deletion": "O(N)"
                }
            },
        )
        l1_2 = Lesson(
            id=uuid.uuid4(),
            module_id=m1.id,
            title="Array Step-by-Step Traversal Visualizer",
            slug="arrays-step-by-step-traversal",
            content_type="VISUALIZATION",
            order_index=2,
            estimated_minutes=15,
            content_json={
                "visualizer_type": "array_traversal",
                "initial_array": [14, 28, 42, 56, 70, 84, 98],
                "description": "Observe how pointer index increments sequentially through memory addresses."
            },
        )
        db.add_all([l1_1, l1_2])

        # Module 1.2: Two Pointers & Sliding Window
        m2 = CourseModule(
            id=uuid.uuid4(),
            course_id=course_arrays.id,
            title="Module 2: Two Pointer & Window Patterns",
            order_index=2,
        )
        db.add(m2)
        db.flush()

        l2_1 = Lesson(
            id=uuid.uuid4(),
            module_id=m2.id,
            title="Two Sum II - Input Array Is Sorted",
            slug="arrays-two-sum-sorted",
            content_type="PROBLEM",
            order_index=1,
            estimated_minutes=20,
            content_json={
                "difficulty": "EASY",
                "problem_statement": "Given a 1-indexed array of integers numbers that is already sorted in non-decreasing order, find two numbers such that they add up to a specific target number.",
                "examples": [
                    {
                        "input": "numbers = [2,7,11,15], target = 9",
                        "output": "[1,2]",
                        "explanation": "The sum of 2 and 7 is 9. Therefore, index1 = 1, index2 = 2. We return [1, 2]."
                    }
                ],
                "constraints": [
                    "2 <= numbers.length <= 3 * 10^4",
                    "-1000 <= numbers[i] <= 1000",
                    "numbers is sorted in non-decreasing order."
                ]
            },
        )
        l2_2 = Lesson(
            id=uuid.uuid4(),
            module_id=m2.id,
            title="Container With Most Water",
            slug="arrays-container-with-most-water",
            content_type="PROBLEM",
            order_index=2,
            estimated_minutes=25,
            content_json={
                "difficulty": "MEDIUM",
                "problem_statement": "You are given an integer array height of length n. There are n vertical lines drawn such that the two endpoints of the ith line are (i, 0) and (i, height[i]). Find two lines that together with the x-axis form a container, such that the container contains the most water.",
                "examples": [
                    {
                        "input": "height = [1,8,6,2,5,4,8,3,7]",
                        "output": "49",
                        "explanation": "The vertical lines are represented by array [1,8,6,2,5,4,8,3,7]. In this case, the max area of water the container can contain is 49."
                    }
                ],
                "constraints": [
                    "n == height.length",
                    "2 <= n <= 10^5",
                    "0 <= height[i] <= 10^4"
                ]
            },
        )
        db.add_all([l2_1, l2_2])

        # Course 2: Binary Trees & BSTs
        course_trees = Course(
            id=uuid.uuid4(),
            title="Binary Trees & Search Trees",
            slug="binary-trees",
            description="Deep dive into recursive tree traversals (Inorder, Preorder, Postorder), BFS Level Order, Height balancing, and Binary Search Tree invariants.",
            thumbnail_url="https://images.unsplash.com/photo-1509228468518-180dd4864904?w=800&auto=format&fit=crop&q=80",
            difficulty="INTERMEDIATE",
            topic_category="Data Structures",
            is_published=True,
            created_by=creator_id,
        )
        db.add(course_trees)
        db.flush()

        m3 = CourseModule(
            id=uuid.uuid4(),
            course_id=course_trees.id,
            title="Module 1: Tree Fundamentals & Traversals",
            order_index=1,
        )
        db.add(m3)
        db.flush()

        l3_1 = Lesson(
            id=uuid.uuid4(),
            module_id=m3.id,
            title="Binary Tree Properties and Recursive Traversals",
            slug="trees-properties-recursive-traversals",
            content_type="CONCEPT",
            order_index=1,
            estimated_minutes=15,
            content_json={
                "overview": "A binary tree is a hierarchical data structure where each node has at most two children, referred to as the left child and the right child.",
                "key_points": [
                    "Inorder (Left, Root, Right) produces sorted sequences for Binary Search Trees.",
                    "Preorder (Root, Left, Right) is ideal for serialization and copying trees.",
                    "Postorder (Left, Right, Root) is ideal for bottom-up calculation (e.g., maximum depth, diameter)."
                ],
                "code_example": "void inorder(TreeNode* root) {\n    if (!root) return;\n    inorder(root->left);\n    cout << root->val << ' ';\n    inorder(root->right);\n}",
                "complexity": {
                    "time": "O(N) visiting each node exactly once",
                    "space": "O(H) recursion stack space, where H is tree height (O(log N) balanced, O(N) skewed)"
                }
            },
        )
        l3_2 = Lesson(
            id=uuid.uuid4(),
            module_id=m3.id,
            title="Interactive Binary Tree Visualizer",
            slug="trees-interactive-visualizer",
            content_type="VISUALIZATION",
            order_index=2,
            estimated_minutes=20,
            content_json={
                "visualizer_type": "binary_tree",
                "initial_tree": {"val": 10, "left": {"val": 5, "left": {"val": 2}, "right": {"val": 7}}, "right": {"val": 15, "right": {"val": 20}}},
                "description": "Step through BFS and DFS node exploration visually."
            },
        )
        db.add_all([l3_1, l3_2])

        # Course 3: Dynamic Programming
        course_dp = Course(
            id=uuid.uuid4(),
            title="Dynamic Programming Mastery",
            slug="dynamic-programming",
            description="Break down complex problems with optimal substructure and overlapping subproblems using memoization (top-down) and tabulation (bottom-up).",
            thumbnail_url="https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop&q=80",
            difficulty="ADVANCED",
            topic_category="Algorithms",
            is_published=True,
            created_by=creator_id,
        )
        db.add(course_dp)
        db.flush()

        m4 = CourseModule(
            id=uuid.uuid4(),
            course_id=course_dp.id,
            title="Module 1: 1D Dynamic Programming",
            order_index=1,
        )
        db.add(m4)
        db.flush()

        l4_1 = Lesson(
            id=uuid.uuid4(),
            module_id=m4.id,
            title="The Core Principles of Dynamic Programming",
            slug="dp-core-principles",
            content_type="CONCEPT",
            order_index=1,
            estimated_minutes=15,
            content_json={
                "overview": "Dynamic programming is both a mathematical optimization method and a computer programming method. It solves problems by combining solutions to subproblems.",
                "key_points": [
                    "1. Overlapping Subproblems: The same subproblems are solved multiple times.",
                    "2. Optimal Substructure: Optimal solution to problem contains optimal solutions to subproblems.",
                    "Memoization stores results of expensive function calls in a cache.",
                    "Tabulation builds DP table iteratively from base cases up."
                ],
                "code_example": "int climbStairs(int n) {\n    if (n <= 2) return n;\n    int a = 1, b = 2;\n    for (int i = 3; i <= n; i++) {\n        int temp = a + b;\n        a = b;\n        b = temp;\n    }\n    return b;\n}"
            },
        )
        db.add(l4_1)

        db.commit()
        print("Successfully seeded courses, modules, and lessons!")

    except Exception as e:
        db.rollback()
        print("Error seeding courses:", e)
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_courses()
