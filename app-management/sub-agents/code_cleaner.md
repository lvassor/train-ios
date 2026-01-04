# Code Cleaner Sub-Agent

Crawl the entire codebase and identify code hygiene issues to lean down the project.

## Scan For

1. **Dead Code**
   - Unused functions, methods, and computed properties
   - Unused imports and type aliases
   - Unreachable code paths
   - Commented-out code blocks

2. **Debug Artifacts**
   - `print()` statements
   - `debugPrint()` and `dump()` calls
   - `#if DEBUG` blocks that should be removed
   - Hardcoded test values

3. **Logging Issues**
   - Excessive or verbose logging
   - Inconsistent logging patterns
   - Missing error logging where needed

4. **Code Quality**
   - Bloated functions (>50 lines)
   - Deeply nested conditionals
   - Magic numbers without constants
   - Duplicate code blocks (copy-paste)
   - Overly complex expressions

5. **Comments**
   - Outdated or misleading comments
   - TODO/FIXME items that need addressing
   - Commented explanations for obvious code

## Output

Present findings on screen for approval before making changes. Group by file:

| File | Line | Issue Type | Current Code | Action |
|------|------|------------|--------------|--------|

For each issue, specify whether to DELETE, REFACTOR, or FLAG FOR REVIEW. Wait for user approval before implementing.

Do not cover: architectural patterns, algorithm efficiency (handled by app_optimiser).
