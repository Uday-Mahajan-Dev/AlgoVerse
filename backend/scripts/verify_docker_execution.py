#!/usr/bin/env python3
"""
Verify live Docker Judge0 code execution for Python, Java, and C++.
Pings Judge0 API, executes real submissions, and outputs verdicts, CPU time, memory, and stdout.
"""

import sys
import time
import requests

JUDGE0_URL = "http://localhost:2358"

TEST_CASES = [
    {
        "language": "Python 3",
        "language_id": 71,
        "source_code": 'print("DOCKER_PY_SUCCESS")',
        "expected": "DOCKER_PY_SUCCESS",
    },
    {
        "language": "Java (OpenJDK 13)",
        "language_id": 62,
        "source_code": """public class Main {
    public static void main(String[] args) {
        System.out.print("DOCKER_JAVA_SUCCESS");
    }
}""",
        "expected": "DOCKER_JAVA_SUCCESS",
    },
    {
        "language": "C++ (GCC 9.2)",
        "language_id": 54,
        "source_code": """#include <iostream>
int main() {
    std::cout << "DOCKER_CPP_SUCCESS";
    return 0;
}""",
        "expected": "DOCKER_CPP_SUCCESS",
    },
]


def check_health() -> bool:
    print("=" * 60)
    print(f"[*] Checking Judge0 Docker status at {JUDGE0_URL} ...")
    try:
        resp = requests.get(f"{JUDGE0_URL}/languages", timeout=4)
        if resp.status_code == 200:
            languages = resp.json()
            print(f"[+] Judge0 is ONLINE and healthy! ({len(languages)} languages available)")
            return True
        else:
            print(f"[-] Judge0 returned HTTP {resp.status_code}: {resp.text}")
            return False
    except requests.exceptions.ConnectionError:
        print(f"[-] FAILED to connect to Judge0 at {JUDGE0_URL}.")
        print("    Ensure Docker containers are running: 'docker-compose up -d'")
        return False
    except Exception as e:
        print(f"[-] Unexpected error connecting to Judge0: {e}")
        return False


def run_submission(test_case: dict) -> bool:
    lang = test_case["language"]
    lang_id = test_case["language_id"]
    code = test_case["source_code"]
    expected = test_case["expected"]

    print("-" * 60)
    print(f"[*] Submitting {lang} snippet (ID: {lang_id}) to Judge0 container...")

    url = f"{JUDGE0_URL}/submissions?base64_encoded=false&wait=true"
    payload = {
        "source_code": code,
        "language_id": lang_id,
        "stdin": "",
        "cpu_time_limit": 5.0,
        "memory_limit": 512000,
        "max_processes_and_or_threads": 120,
        "enable_per_process_and_thread_time_limit": True,
        "enable_per_process_and_thread_memory_limit": True,
    }

    try:
        t0 = time.perf_counter()
        resp = requests.post(url, json=payload, headers={"Content-Type": "application/json"}, timeout=15)
        elapsed_sec = time.perf_counter() - t0

        if resp.status_code not in (200, 201):
            print(f"[-] HTTP Error {resp.status_code}: {resp.text}")
            return False

        data = resp.json()
        status_info = data.get("status", {})
        status_desc = status_info.get("description", "Unknown")
        status_id = status_info.get("id", 0)

        stdout = (data.get("stdout") or "").strip()
        stderr = (data.get("stderr") or "").strip()
        compile_output = (data.get("compile_output") or "").strip()
        cpu_time = data.get("time") or "0"
        memory = data.get("memory") or "0"

        print(f"    Verdict:        {status_desc} (Status ID: {status_id})")
        print(f"    CPU Time:       {cpu_time}s")
        print(f"    Memory Used:    {memory} KB")
        print(f"    Round-trip:     {elapsed_sec:.2f}s")
        print(f"    Container Stdout: '{stdout}'")

        if compile_output:
            print(f"    Compile Output: {compile_output}")
        if stderr:
            print(f"    Container Stderr: {stderr}")

        if status_id == 3 and expected in stdout:
            print(f"[+] SUCCESS: {lang} execution verified in Docker container!")
            return True
        else:
            print(f"[-] FAILED: Expected '{expected}', got '{stdout}'. Verdict: {status_desc}")
            return False

    except Exception as e:
        print(f"[-] Submission failed with exception: {e}")
        return False


def main():
    print("\n" + "=" * 60)
    print("      ALGOVERSE DOCKER / JUDGE0 EXECUTION VERIFIER")
    print("=" * 60)

    if not check_health():
        print("\n[FAIL] VERIFICATION FAILED: Judge0 Docker container is unreachable.")
        sys.exit(1)

    all_passed = True
    for tc in TEST_CASES:
        success = run_submission(tc)
        if not success:
            all_passed = False

    print("\n" + "=" * 60)
    if all_passed:
        print("[SUCCESS] ALL 3 DOCKER EXECUTION TESTS (Python, Java, C++) PASSED SUCCESSFULLY!")
        print("=" * 60 + "\n")
        sys.exit(0)
    else:
        print("[FAIL] SOME TESTS FAILED. Please review container logs.")
        print("=" * 60 + "\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
