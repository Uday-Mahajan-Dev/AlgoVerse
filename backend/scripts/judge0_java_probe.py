import base64
import io
import json
import os
import sys
import zipfile
import requests

# Ensure app imports work if needed
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from app.core.config import settings

JUDGE0_URL = (settings.JUDGE0_API_URL or "http://localhost:2358").rstrip("/")

JAVA_CODE = """import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        if (sc.hasNextInt()) {
            int a = sc.nextInt();
            int b = sc.nextInt();
            System.out.println(a + b);
        }
    }
}
"""

STDIN_DATA = "15 27\n"
EXPECTED_OUTPUT = "42"


def build_java_zip(class_name: str, java_code: str) -> str:
    """Build in-memory zip for language 89 containing <ClassName>.java, compile, and run scripts."""
    compile_script = f"#!/bin/bash\njavac -encoding UTF-8 {class_name}.java\n"
    run_script = (
        f"#!/bin/bash\n"
        f"java -XX:+UseSerialGC -XX:-UseCompressedClassPointers "
        f"-XX:MaxMetaspaceSize=128m -Xss64m -Xmx256m -Xshare:off {class_name}\n"
    )

    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", compression=zipfile.ZIP_DEFLATED) as z:
        # User code
        z.writestr(f"{class_name}.java", java_code)

        # compile script with unix executable permissions (0755)
        compile_info = zipfile.ZipInfo("compile")
        compile_info.external_attr = 0o755 << 16
        z.writestr(compile_info, compile_script.encode("utf-8"))

        # run script with unix executable permissions (0755)
        run_info = zipfile.ZipInfo("run")
        run_info.external_attr = 0o755 << 16
        z.writestr(run_info, run_script.encode("utf-8"))

    return base64.b64encode(buf.getvalue()).decode("utf-8")


def probe():
    print(f"=== Judge0 Java Diagnostics Probe ===")
    print(f"Target URL: {JUDGE0_URL}")

    # 1. Health check & Config info
    try:
        about_resp = requests.get(f"{JUDGE0_URL}/about", timeout=4)
        print(f"About: {about_resp.status_code} -> {about_resp.text[:120]}")
    except Exception as e:
        print(f"Failed to reach {JUDGE0_URL}/about: {e}")

    max_mem_kb = 512000
    try:
        cfg_resp = requests.get(f"{JUDGE0_URL}/config_info", timeout=4)
        if cfg_resp.status_code == 200:
            cfg = cfg_resp.json()
            print(f"Config Info: {cfg}")
            max_mem_kb = cfg.get("max_memory_limit", max_mem_kb)
        else:
            print(f"Config Info endpoint returned {cfg_resp.status_code}")
    except Exception as e:
        print(f"Could not fetch config_info: {e}")

    # Check languages
    try:
        langs_resp = requests.get(f"{JUDGE0_URL}/languages", timeout=4)
        if langs_resp.status_code == 200:
            langs = langs_resp.json()
            lang_ids = {l.get("id"): l.get("name") for l in langs}
            print(f"Java 62 present? {62 in lang_ids} ({lang_ids.get(62)})")
            print(f"Language 89 present? {89 in lang_ids} ({lang_ids.get(89)})")
        else:
            print(f"Languages returned {langs_resp.status_code}")
    except Exception as e:
        print(f"Could not fetch languages: {e}")

    results = []

    # Variant (a): Current settings (language_id 62, memory_limit=512000 KB)
    print("\n--- Testing Variant (a): language_id 62, memory_limit=512000 KB ---")
    payload_a = {
        "source_code": JAVA_CODE,
        "language_id": 62,
        "stdin": STDIN_DATA,
        "cpu_time_limit": 5.0,
        "memory_limit": 512000,
        "enable_per_process_and_thread_time_limit": True,
        "enable_per_process_and_thread_memory_limit": True,
    }
    res_a = execute_submission(payload_a)
    results.append(("Variant (a): lang 62, 512MB", res_a))

    # Variant (b): language_id 62, memory_limit raised to max allowed (e.g. 1048576 KB or max_mem_kb)
    high_mem = max(max_mem_kb, 1048576)
    print(f"\n--- Testing Variant (b): language_id 62, memory_limit={high_mem} KB ---")
    payload_b = {
        "source_code": JAVA_CODE,
        "language_id": 62,
        "stdin": STDIN_DATA,
        "cpu_time_limit": 5.0,
        "memory_limit": high_mem,
        "enable_per_process_and_thread_time_limit": True,
        "enable_per_process_and_thread_memory_limit": True,
    }
    res_b = execute_submission(payload_b)
    results.append((f"Variant (b): lang 62, {high_mem//1024}MB", res_b))

    # Variant (c): language_id 89 (Multi-file program) with custom JVM metaspace flags
    print("\n--- Testing Variant (c): language_id 89 (Multi-file) with JVM flags ---")
    zip_b64 = build_java_zip("Main", JAVA_CODE)
    payload_c = {
        "source_code": "",  # Or comment
        "language_id": 89,
        "additional_files": zip_b64,
        "stdin": STDIN_DATA,
        "cpu_time_limit": 5.0,
        "memory_limit": 512000,
        "enable_per_process_and_thread_time_limit": True,
        "enable_per_process_and_thread_memory_limit": True,
    }
    res_c = execute_submission(payload_c)
    results.append(("Variant (c): lang 89, multi-file", res_c))

    print("\n=== SUMMARY TABLE ===")
    print(f"{'Variant':<32} | {'Status ID':<10} | {'Status Desc':<16} | {'Stdout':<10} | {'Stderr / Error'}")
    print("-" * 90)
    for name, r in results:
        status_id = r.get("status", {}).get("id", "ERR")
        status_desc = r.get("status", {}).get("description", "Unknown")
        stdout = (r.get("stdout") or "").strip().replace("\n", " ")
        stderr = (r.get("stderr") or r.get("compile_output") or r.get("error") or "").strip().replace("\n", " ")
        if len(stderr) > 40:
            stderr = stderr[:37] + "..."
        print(f"{name:<32} | {str(status_id):<10} | {status_desc:<16} | {stdout:<10} | {stderr}")


def execute_submission(payload: dict) -> dict:
    url = f"{JUDGE0_URL}/submissions?base64_encoded=false&wait=true"
    try:
        resp = requests.post(url, json=payload, headers={"Content-Type": "application/json"}, timeout=15)
        print(f"HTTP {resp.status_code}")
        if resp.status_code in (200, 201):
            data = resp.json()
            print(f"Status: {data.get('status')}")
            if data.get('stdout'):
                print(f"Stdout: {repr(data.get('stdout'))}")
            if data.get('stderr'):
                print(f"Stderr: {repr(data.get('stderr'))}")
            if data.get('compile_output'):
                print(f"Compile: {repr(data.get('compile_output'))}")
            return data
        else:
            print(f"Response: {resp.text}")
            return {"error": resp.text, "status": {"id": -1, "description": f"HTTP {resp.status_code}"}}
    except Exception as e:
        print(f"Exception: {e}")
        return {"error": str(e), "status": {"id": -1, "description": "ConnectionError"}}


if __name__ == "__main__":
    probe()
