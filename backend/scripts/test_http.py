import urllib.request
import json

def test_api():
    # 1. Test published courses
    req = urllib.request.Request("http://127.0.0.1:8000/api/v1/courses")
    with urllib.request.urlopen(req) as res:
        assert res.status == 200
        courses = json.loads(res.read().decode())
        print(f"GET /api/v1/courses -> status: {res.status}, count: {len(courses)}")
        for c in courses:
            print(f"  - {c['title']} (slug: {c['slug']}, modules: {c['module_count']}, lessons: {c['total_lessons']})")

    # 2. Test course detail for 'arrays'
    req_detail = urllib.request.Request("http://127.0.0.1:8000/api/v1/courses/arrays")
    with urllib.request.urlopen(req_detail) as res:
        assert res.status == 200
        detail = json.loads(res.read().decode())
        print(f"\nGET /api/v1/courses/arrays -> status: {res.status}")
        print(f"Title: {detail['title']}")
        print(f"Modules: {len(detail['modules'])}, Total Lessons: {detail['total_lessons']}")
        for m in detail["modules"]:
            print(f"  Module {m['order_index']}: {m['title']} ({len(m['lessons'])} lessons)")

    print("\nHTTP verification passed!")

if __name__ == "__main__":
    test_api()
