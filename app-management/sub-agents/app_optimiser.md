# App Optimiser Sub-Agent

Analyse the codebase for algorithmic and architectural optimisation opportunities.

## Focus Areas

1. **Algorithm Efficiency**
   - Review programme generation algorithm for performance
   - Check database query efficiency (N+1 problems, missing indexes)
   - Identify expensive computations that could be cached or memoised

2. **Architectural Patterns**
   - Assess MVVM implementation and data flow
   - Review service layer design and dependency injection
   - Check for proper separation of concerns

3. **Swift Best Practices**
   - Identify opportunities for `final` keyword, protocol extensions
   - Review async/await usage and concurrency patterns
   - Check for main thread blocking operations

4. **Data Flow**
   - Analyse state management across views
   - Review database transaction boundaries
   - Check for redundant data fetching

## Output

Present findings on screen for approval before making changes:
- List issues by priority (Critical/High/Medium/Low)
- Show current code and proposed fix for each
- Wait for user approval before implementing any changes

Do not cover: code cleanup, print statements, comments, unused code (handled by code_cleaner).
