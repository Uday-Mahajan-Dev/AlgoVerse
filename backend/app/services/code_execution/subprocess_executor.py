import ast
import subprocess
import sys
import time

from app.services.code_execution.base_executor import (
    BaseCodeExecutor,
    ExecutionResult,
)


class SecurityViolation(Exception):
    pass


class ASTSecurityValidator(ast.NodeVisitor):
    FORBIDDEN_IMPORTS = {
        "os", "subprocess", "shutil", "socket", "http", "urllib",
        "requests", "ctypes", "threading", "multiprocessing", "signal",
        "pty", "commands", "posix", "nt", "importlib", "pickle", "shelve",
        "dbm", "sqlite3", "webbrowser", "pathlib",
    }

    FORBIDDEN_CALLS = {
        "open", "eval", "exec", "__import__", "globals", "locals", "vars",
        "compile", "breakpoint", "input_orig",
    }

    def visit_Import(self, node):
        for alias in node.names:
            root_module = alias.name.split(".")[0]
            if root_module in self.FORBIDDEN_IMPORTS:
                raise SecurityViolation(f"Import of '{alias.name}' is not allowed for security reasons.")
        self.generic_visit(node)

    def visit_ImportFrom(self, node):
        if node.module:
            root_module = node.module.split(".")[0]
            if root_module in self.FORBIDDEN_IMPORTS:
                raise SecurityViolation(f"Import from '{node.module}' is not allowed for security reasons.")
        self.generic_visit(node)

    def visit_Call(self, node):
        if isinstance(node.func, ast.Name) and node.func.id in self.FORBIDDEN_CALLS:
            raise SecurityViolation(f"Function call '{node.func.id}()' is blocked for security reasons.")
        self.generic_visit(node)


class SubprocessExecutor(BaseCodeExecutor):
    def execute(
        self,
        source_code: str,
        language: str,
        stdin_input: str,
        time_limit_ms: int = 2000,
        memory_limit_mb: int = 64,
    ) -> ExecutionResult:
        lang_key = (language or "").strip().lower()

        if lang_key not in ("python", "python3", "py"):
            if lang_key in ("java", "cpp", "c++", "c", "javascript", "js", "typescript", "ts"):
                return ExecutionResult(
                    stdout="",
                    stderr="This language requires the Judge0 execution engine. Please start Docker and run docker-compose up.",
                    exit_code=1,
                    execution_time_ms=0,
                    memory_used_kb=0,
                    timed_out=False,
                    compile_error=True,
                )
            return ExecutionResult(
                stdout="",
                stderr=f"Unsupported language: '{language}'. This language requires Judge0 or Python local executor.",
                exit_code=1,
                execution_time_ms=0,
                memory_used_kb=0,
                timed_out=False,
                compile_error=True,
            )

        # 1. AST Security Guard for Python
        try:
            tree = ast.parse(source_code)
            validator = ASTSecurityValidator()
            validator.visit(tree)
        except SyntaxError as e:
            return ExecutionResult(
                stdout="",
                stderr=f"SyntaxError: {str(e)}",
                exit_code=1,
                execution_time_ms=0,
                memory_used_kb=0,
                timed_out=False,
                compile_error=True,
            )
        except SecurityViolation as e:
            return ExecutionResult(
                stdout="",
                stderr=f"SecurityViolation: {str(e)}",
                exit_code=1,
                execution_time_ms=0,
                memory_used_kb=0,
                timed_out=False,
                compile_error=True,
            )
        except Exception as e:
            return ExecutionResult(
                stdout="",
                stderr=f"CompileError: {str(e)}",
                exit_code=1,
                execution_time_ms=0,
                memory_used_kb=0,
                timed_out=False,
                compile_error=True,
            )

        # 2. Subprocess Execution
        timeout_seconds = max(0.5, time_limit_ms / 1000.0)
        start_time = time.perf_counter()

        try:
            python_bin = sys.executable or "python"
            process = subprocess.Popen(
                [python_bin, "-u", "-c", source_code],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )

            stdout, stderr = process.communicate(
                input=stdin_input,
                timeout=timeout_seconds,
            )
            elapsed_ms = int((time.perf_counter() - start_time) * 1000)

            return ExecutionResult(
                stdout=stdout or "",
                stderr=stderr or "",
                exit_code=process.returncode,
                execution_time_ms=elapsed_ms,
                memory_used_kb=1024,  # Approximate baseline
                timed_out=False,
                compile_error=False,
            )
        except subprocess.TimeoutExpired:
            process.kill()
            stdout, stderr = process.communicate()
            elapsed_ms = int((time.perf_counter() - start_time) * 1000)
            return ExecutionResult(
                stdout=stdout or "",
                stderr="Time Limit Exceeded (Execution timed out).",
                exit_code=1,
                execution_time_ms=elapsed_ms,
                memory_used_kb=1024,
                timed_out=True,
                compile_error=False,
            )
        except Exception as e:
            return ExecutionResult(
                stdout="",
                stderr=f"Runtime error: {str(e)}",
                exit_code=1,
                execution_time_ms=0,
                memory_used_kb=0,
                timed_out=False,
                compile_error=False,
            )
