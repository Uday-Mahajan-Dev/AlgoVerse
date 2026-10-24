import base64
import io
import unittest
import zipfile
from unittest.mock import MagicMock, patch

from app.services.code_execution.judge0_executor import Judge0Executor
from app.services.code_execution.executor_factory import check_judge0_reachability


class TestJudge0JavaMultiFile(unittest.TestCase):
    def setUp(self):
        self.executor = Judge0Executor()

    def test_class_name_detection_defaults_to_main(self):
        code_without_public = """
class Helper {
    int x;
}
"""
        name = Judge0Executor.detect_java_class_name(code_without_public)
        self.assertEqual(name, "Helper")

        code_empty = ""
        name_empty = Judge0Executor.detect_java_class_name(code_empty)
        self.assertEqual(name_empty, "Main")

    def test_class_name_detection_finds_public_class(self):
        code_custom = """
// public class CommentedOutClass
/*
public class MultiLineComment
*/
public class Solution {
    public static void main(String[] args) {
        System.out.println("hello");
    }
}
"""
        name = Judge0Executor.detect_java_class_name(code_custom)
        self.assertEqual(name, "Solution")

    def test_build_java_zip_structure(self):
        code = "public class TwoSum { public static void main(String[] args) {} }"
        b64_zip = Judge0Executor.build_java_zip("TwoSum", code)
        zip_bytes = base64.b64decode(b64_zip)

        with zipfile.ZipFile(io.BytesIO(zip_bytes), "r") as z:
            names = z.namelist()
            self.assertIn("TwoSum.java", names)
            self.assertIn("compile", names)
            self.assertIn("run", names)

            # Check compile script
            compile_content = z.read("compile").decode("utf-8")
            self.assertIn("#!/bin/bash", compile_content)
            self.assertIn("javac -encoding UTF-8 TwoSum.java", compile_content)

            # Check run script
            run_content = z.read("run").decode("utf-8")
            self.assertIn("#!/bin/bash", run_content)
            self.assertIn("-XX:-UseCompressedClassPointers", run_content)
            self.assertIn("-XX:MaxMetaspaceSize=128m", run_content)
            self.assertIn("TwoSum", run_content)

            # Check file permissions (executable bits)
            compile_info = z.getinfo("compile")
            run_info = z.getinfo("run")
            self.assertTrue(bool(compile_info.external_attr >> 16 & 0o111))
            self.assertTrue(bool(run_info.external_attr >> 16 & 0o111))

    def test_prepare_payload_java_uses_language_89(self):
        java_code = "public class Main { public static void main(String[] args) {} }"
        payload, lang_key = self.executor._prepare_payload(
            source_code=java_code,
            language="java",
            stdin_input="10 20",
            time_limit_ms=3000,
            memory_limit_mb=256,
        )
        self.assertEqual(lang_key, "java")
        self.assertIsNotNone(payload)
        self.assertEqual(payload["language_id"], 89)
        self.assertEqual(payload["source_code"], "")
        self.assertIn("additional_files", payload)
        self.assertEqual(payload["stdin"], "10 20")
        self.assertEqual(payload["cpu_time_limit"], 3.0)
        self.assertGreaterEqual(payload["memory_limit"], 512000)

    def test_prepare_payload_python_and_cpp_unaltered(self):
        py_code = "print(1 + 2)"
        payload_py, _ = self.executor._prepare_payload(py_code, "python", "", 2000, 64)
        self.assertEqual(payload_py["language_id"], 71)
        self.assertEqual(payload_py["source_code"], py_code)
        self.assertNotIn("additional_files", payload_py)

        cpp_code = "#include <iostream>\nint main() { return 0; }"
        payload_cpp, _ = self.executor._prepare_payload(cpp_code, "cpp", "", 2000, 64)
        self.assertEqual(payload_cpp["language_id"], 54)
        self.assertEqual(payload_cpp["source_code"], cpp_code)
        self.assertNotIn("additional_files", payload_cpp)

    @patch("requests.post")
    def test_mock_judge0_java_execution_success(self, mock_post):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "status": {"id": 3, "description": "Accepted"},
            "stdout": "42\n",
            "stderr": None,
            "compile_output": None,
            "time": "0.15",
            "memory": 24500,
        }
        mock_post.return_value = mock_response

        java_code = "public class Main { public static void main(String[] args) { System.out.println(42); } }"
        result = self.executor.execute(
            source_code=java_code,
            language="java",
            stdin_input="",
        )

        self.assertEqual(result.exit_code, 0)
        self.assertEqual(result.stdout.strip(), "42")
        self.assertFalse(result.compile_error)
        self.assertFalse(result.timed_out)

    @patch("requests.post")
    def test_mock_judge0_java_compilation_error(self, mock_post):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "status": {"id": 6, "description": "Compilation Error"},
            "stdout": None,
            "stderr": "",
            "compile_output": "Main.java:2: error: ';' expected\n",
            "time": None,
            "memory": None,
        }
        mock_post.return_value = mock_response

        java_code = "public class Main { invalid syntax }"
        result = self.executor.execute(
            source_code=java_code,
            language="java",
            stdin_input="",
        )

        self.assertTrue(result.compile_error)
        self.assertEqual(result.exit_code, 1)
        self.assertIn("Main.java:2: error", result.stderr)

    @patch("requests.post")
    def test_mock_judge0_vm_initialization_failure_mapping(self, mock_post):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "status": {"id": 11, "description": "Runtime Error (NZEC)"},
            "stdout": None,
            "stderr": "Error occurred during initialization of VM\nCould not allocate metaspace: 1073741824 bytes",
            "compile_output": None,
            "time": "0.02",
            "memory": 12000,
        }
        mock_post.return_value = mock_response

        java_code = "public class Main { public static void main(String[] args) {} }"
        result = self.executor.execute(
            source_code=java_code,
            language="java",
            stdin_input="",
        )

        self.assertFalse(result.compile_error)
        self.assertEqual(result.exit_code, 1)
        self.assertEqual(result.stderr, "Java runtime failed to start on the judge server")

    def test_live_judge0_integration(self):
        """Integration test against configured Judge0 (skips if unreachable)."""
        if not check_judge0_reachability():
            raise unittest.SkipTest("Configured Judge0 is not reachable; skipping live execution test.")

        # Test Python AC
        py_res = self.executor.execute("import sys; a, b = map(int, sys.stdin.read().split()); print(a + b)", "python", "10 20\n")
        self.assertEqual(py_res.exit_code, 0)
        self.assertEqual(py_res.stdout.strip(), "30")

        # Test Java AC
        java_code = """import java.util.Scanner;
public class Main {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.println(sc.nextInt() + sc.nextInt());
    }
}"""
        java_res = self.executor.execute(java_code, "java", "15 25\n")
        self.assertEqual(java_res.exit_code, 0)
        self.assertEqual(java_res.stdout.strip(), "40")

        # Test Java Syntax Error -> CE
        bad_java = "public class Main { syntax error }"
        ce_res = self.executor.execute(bad_java, "java", "")
        self.assertTrue(ce_res.compile_error)


if __name__ == "__main__":
    unittest.main()
