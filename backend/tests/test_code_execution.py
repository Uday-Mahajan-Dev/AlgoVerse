import ast
import unittest

from app.services.code_execution.base_executor import ExecutionResult
from app.services.code_execution.subprocess_executor import (
    ASTSecurityValidator,
    SecurityViolation,
    SubprocessExecutor,
)


class TestCodeExecution(unittest.TestCase):
    def test_ast_security_validator_blocks_malicious_imports(self):
        malicious_code = """
import os
os.system('ls')
"""
        tree = ast.parse(malicious_code)
        validator = ASTSecurityValidator()
        with self.assertRaises(SecurityViolation):
            validator.visit(tree)

    def test_ast_security_validator_blocks_open_call(self):
        malicious_code = """
f = open('secret.txt', 'r')
"""
        tree = ast.parse(malicious_code)
        validator = ASTSecurityValidator()
        with self.assertRaises(SecurityViolation):
            validator.visit(tree)

    def test_ast_security_validator_allows_safe_code(self):
        safe_code = """
import sys
from typing import List

def solve():
    lines = sys.stdin.read().split()
    if not lines:
        return
    print(" ".join(lines))

if __name__ == '__main__':
    solve()
"""
        tree = ast.parse(safe_code)
        validator = ASTSecurityValidator()
        # Should not raise
        validator.visit(tree)

    def test_subprocess_executor_python_execution(self):
        executor = SubprocessExecutor()
        code = """
import sys
data = sys.stdin.read().split()
print(" ".join(reversed(data)))
"""
        result = executor.execute(
            source_code=code,
            language="python",
            stdin_input="hello world 123",
            time_limit_ms=2000,
            memory_limit_mb=64,
        )
        self.assertFalse(result.compile_error)
        self.assertEqual(result.exit_code, 0)
        self.assertEqual(result.stdout.strip(), "123 world hello")

    def test_subprocess_executor_java_docker_requirement_message(self):
        executor = SubprocessExecutor()
        result = executor.execute(
            source_code="class Solution {}",
            language="java",
            stdin_input="",
            time_limit_ms=2000,
            memory_limit_mb=64,
        )
        self.assertTrue(result.compile_error)
        self.assertIn("requires the Judge0 execution engine", result.stderr)


if __name__ == "__main__":
    unittest.main()
