# AlgoVerse — Interactive DSA Learning Platform

AlgoVerse is a pair-programming, interactive Data Structures and Algorithms learning platform featuring deterministic visualization engines and multi-language sandboxed code execution.

## Code Execution Engine (Judge0)

AlgoVerse uses Judge0 as its multi-language execution engine for Python, Java, and C++.

### Starting Judge0 locally with Docker:
```bash
cd backend
docker-compose -f docker-compose.judge0.yml up -d
```

Verify Judge0 status:
```bash
curl http://localhost:2358/languages
```

*Note: If Docker is not running on the local host, AlgoVerse automatically falls back to an internal secure AST-guarded Python executor.*
