import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent))

import app.db.base  # noqa: F401
from app.db.session import SessionLocal
from app.models.course import Course
from app.models.course_module import CourseModule
from app.models.lesson import Lesson
from app.services.course_service import CourseService
from scripts.seed_arrays_course import seed_arrays_course


def verify_arrays_course():
    db = SessionLocal()
    try:
        print("=" * 80)
        print("VERIFYING ARRAYS COURSE SEED DATA")
        print("=" * 80)

        # 1. Fetch published courses
        published = CourseService.get_published_courses(db)
        print(f"Published courses count: {len(published)}")
        for p in published:
            print(f"  - {p.title} (slug: {p.slug}, published: True, modules: {p.module_count}, total_lessons: {p.total_lessons})")

        assert len(published) == 1, f"Expected exactly 1 published course, got {len(published)}"
        assert published[0].slug == "arrays", f"Expected published slug 'arrays', got {published[0].slug}"

        # 2. Fetch Course detail via Service
        detail = CourseService.get_course_detail(db, "arrays")
        print(f"\nCourse Detail: '{detail.title}' ({detail.slug})")
        print(f"Description: {detail.description}")
        print(f"Difficulty: {detail.difficulty} | Category: {detail.topic_category}")
        print(f"Modules: {len(detail.modules)} | Total Lessons: {detail.total_lessons}")

        # Programmatic counters
        concept_count = 0
        visualization_count = 0
        problem_count = 0
        algorithm_names_set = set()

        print("\n" + "-" * 80)
        print("FULL SYLLABUS TREE:")
        print("-" * 80)

        for module in detail.modules:
            print(f"\n[MODULE {module.order_index}] {module.title} ({len(module.lessons)} lessons)")
            for lesson in module.lessons:
                cjson = lesson.content_json or {}
                algo_info = ""
                if lesson.content_type == "CONCEPT":
                    concept_count += 1
                elif lesson.content_type == "VISUALIZATION":
                    visualization_count += 1
                    if "algorithm_name" in cjson:
                        algo_name = cjson["algorithm_name"]
                        algorithm_names_set.add(algo_name)
                        algo_info = f" -> algo: {algo_name}"
                        snippet = cjson.get("code_snippet", "")
                        assert len(snippet.strip()) > 0, f"Empty code snippet in {lesson.slug}"
                    elif "algorithm_names" in cjson:
                        names = cjson["algorithm_names"]
                        for n in names:
                            algorithm_names_set.add(n)
                        algo_info = f" -> algos: {names}"
                        snippets = cjson.get("code_snippets", {})
                        assert len(snippets) == 2, f"Expected 2 snippets in dual-algo {lesson.slug}"
                        for k, v in snippets.items():
                            assert len(v.strip()) > 0, f"Empty snippet for {k} in {lesson.slug}"
                elif lesson.content_type == "PROBLEM":
                    problem_count += 1
                    algo_info = f" -> starter_code: {'yes' if 'starter_code' in cjson else 'no'}"

                print(f"    L{lesson.order_index:02d} [{lesson.content_type:<13}] {lesson.title:<40} ({lesson.estimated_minutes:2d} min){algo_info}")

        print("\n" + "=" * 80)
        print("PROGRAMMATIC ASSERTIONS:")
        print("=" * 80)

        assert len(detail.modules) == 4, f"Expected 4 modules, got {len(detail.modules)}"
        print("  [PASS] Exactly 4 modules")

        assert detail.total_lessons == 16, f"Expected 16 lessons, got {detail.total_lessons}"
        print("  [PASS] Exactly 16 lessons")

        assert concept_count == 2, f"Expected 2 CONCEPT lessons, got {concept_count}"
        print("  [PASS] Exactly 2 CONCEPT lessons")

        assert visualization_count == 11, f"Expected 11 VISUALIZATION lessons, got {visualization_count}"
        print("  [PASS] Exactly 11 VISUALIZATION lessons")

        assert problem_count == 3, f"Expected 3 PROBLEM lessons, got {problem_count}"
        print("  [PASS] Exactly 3 PROBLEM lessons")

        assert len(algorithm_names_set) == 12, f"Expected 12 distinct algorithm names, got {len(algorithm_names_set)}"
        print(f"  [PASS] Exactly 12 distinct algorithm names across visualizations: {sorted(list(algorithm_names_set))}")

        # 3. Prove Idempotency by re-running seed script
        print("\n" + "-" * 80)
        print("TESTING SEED SCRIPT IDEMPOTENCY (Re-running seed_arrays_course)...")
        print("-" * 80)
        seed_arrays_course()

        # Re-verify counts after re-seeding
        detail_after = CourseService.get_course_detail(db, "arrays")
        assert len(detail_after.modules) == 4
        assert detail_after.total_lessons == 16
        print("  [PASS] Idempotency verified: re-running produces clean 4 modules, 16 lessons without duplication.")

        print("\n" + "=" * 80)
        print("ALL VERIFICATIONS COMPLETED SUCCESSFULLY!")
        print("=" * 80)

    finally:
        db.close()


if __name__ == "__main__":
    verify_arrays_course()
