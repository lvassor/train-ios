# iOS Fitness App Optimization Audit

You are an expert iOS performance engineer. Conduct a comprehensive audit of this Swift fitness app codebase to identify all optimization opportunities related to speed, efficiency, app size, and runtime performance.

## Scope of Analysis

Systematically crawl through the entire codebase and analyze the following areas:

### 1. App Bundle & Download Size
- Analyze asset catalogs for uncompressed or oversized images
- Check for unused assets, fonts, or resources
- Identify unnecessary framework dependencies
- Review embedded libraries that could be replaced with system frameworks
- Look for debug symbols or development-only code in release configurations
- Check for duplicate resources across targets

### 2. Build & Compilation
- Review build settings for optimization flags
- Check for whole module optimization configuration
- Identify slow-compiling code patterns (complex type inference, excessive generics)
- Look for unnecessary bridging headers or Objective-C interop overhead

### 3. CoreData/GRDB Database Layer
- Analyze all database schema definitions for indexing opportunities
- Review queries for N+1 problems and missing batch fetching
- Check for unoptimized joins or subqueries
- Identify missing indexes on frequently queried columns
- Review migration strategies for efficiency
- Look for synchronous database operations on the main thread
- Check for excessive or redundant database calls
- Analyze transaction boundaries and batch operation opportunities
- Review data model normalization vs denormalization tradeoffs
- Check for proper use of lazy loading vs eager loading

### 4. Memory & Object Lifecycle
- Identify retain cycles and potential memory leaks
- Check for improper use of closures without `[weak self]`
- Look for large objects kept in memory unnecessarily
- Review image caching strategies
- Identify objects that should use value types instead of reference types
- Check for autoreleasepool usage in loops

### 5. Concurrency & Threading
- Identify main thread blocking operations
- Review async/await usage and potential improvements
- Check for race conditions or excessive locking
- Look for opportunities to parallelize independent operations
- Review GCD queue usage and potential queue hopping overhead
- Identify unnecessary synchronization

### 6. Code Redundancy & Duplication
- Find duplicate or near-duplicate code blocks
- Identify copy-pasted logic that should be abstracted
- Look for multiple implementations of similar functionality
- Check for redundant computed properties or methods
- Review protocol conformances for unnecessary boilerplate

### 7. Network & Data Loading
- Analyze API call patterns for redundancy
- Check for missing request coalescing or debouncing
- Review caching strategies for network responses
- Identify synchronous network calls
- Look for oversized payloads or unnecessary data fetching
- Check for proper pagination implementation

### 8. UI & Rendering Performance
- Identify expensive view layouts or constraint calculations
- Check for offscreen rendering issues
- Review table/collection view cell reuse implementation
- Look for unnecessary view hierarchy complexity
- Identify animations that could cause frame drops
- Check for main thread image decoding

### 9. Launch Time & App Lifecycle
- Analyze AppDelegate/SceneDelegate for blocking operations
- Check for excessive work during app launch
- Review lazy initialization opportunities
- Identify pre-main overhead (dynamic libraries, +load methods)
- Look for unnecessary early initialization

### 10. Swift-Specific Optimizations
- Check for proper use of `final` keyword on classes
- Identify opportunities for `@inlinable` or `@inline(__always)`
- Review generic constraints for specialization opportunities
- Look for AnyObject vs class protocol usage
- Check for String interpolation in hot paths
- Review optional chaining vs guard statements efficiency

## Output Requirements

After completing the analysis, generate a comprehensive markdown report with the following structure:
Optimization Audit Report
Executive Summary
[Brief overview of findings with total counts per priority level and estimated cumulative impact]
Priority Ranked Fixes
RankPriorityIssueCategoryFile(s)Current ImpactRecommended FixEstimated Improvement1🔴 Critical[Issue title][Category][Files][Impact][Fix][Improvement]2🔴 Critical[Issue title][Category][Files][Impact][Fix][Improvement]3🟠 High[Issue title][Category][Files][Impact][Fix][Improvement]4🟠 High[Issue title][Category][Files][Impact][Fix][Improvement]5🟡 Medium[Issue title][Category][Files][Impact][Fix][Improvement]6🟡 Medium[Issue title][Category][Files][Impact][Fix][Improvement]7🟢 Low[Issue title][Category][Files][Impact][Fix][Improvement]........................
Detailed Findings
[Category Name]
Issue: [Specific Issue Title]

Priority: [🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low]
Location: [File path and line numbers]
Current Code:

swift[Snippet showing the problem]

Problem: [Explanation of why this is inefficient]
Recommended Fix:

swift[Corrected code snippet]
```
- **Expected Impact:** [Quantified improvement where possible]

[Repeat for each finding]

## Database-Specific Findings
[Detailed GRDB/CoreData analysis including schema recommendations, query optimizations, and indexing strategies]

## App Size Analysis
[Breakdown of bundle size contributors with specific reduction strategies and estimated savings in MB]

## Quick Wins
[Bulleted list of simple fixes that can be implemented in under 30 minutes each]

## Long-term Refactoring Recommendations
[Architectural changes for sustained performance improvement that require more significant effort]

## Metrics Summary
| Metric | Current (Estimated) | After Optimization (Projected) |
|--------|---------------------|-------------------------------|
| App Bundle Size | X MB | Y MB |
| Cold Launch Time | X sec | Y sec |
| Average Query Time | X ms | Y ms |
| Memory Footprint | X MB | Y MB |
```

## Priority Level Definitions

- 🔴 **Critical**: Directly impacts user experience, causes noticeable lag, significantly bloats app size, or blocks main thread. Fix immediately.
- 🟠 **High**: Measurable performance impact, contributes to slower operations or increased resource usage. Fix in next sprint.
- 🟡 **Medium**: Suboptimal patterns that accumulate over time or affect specific user flows. Schedule for optimization pass.
- 🟢 **Low**: Minor inefficiencies or code hygiene issues with minimal user-facing impact. Address during routine maintenance.

## Ranking Criteria

Prioritize fixes based on:
1. **User-perceived impact** (launch time, UI responsiveness, data loading speed)
2. **App Store impact** (download size, install size)
3. **Implementation complexity** (quick wins ranked higher than major refactors with equal impact)
4. **Risk level** (lower risk changes ranked higher)
5. **Cumulative effect** (fixes that unlock other optimizations)

## Execution Instructions

1. Start by mapping the project structure and identifying all Swift files, assets, and configuration files
2. Analyze each category systematically, taking notes on findings
3. For database analysis, examine all GRDB model definitions, query builders, and migration files
4. Cross-reference findings to identify root causes vs symptoms
5. Quantify impact where possible using static analysis metrics
6. Generate the final ranked report with all findings in a single prioritized table

Save the complete report to: `optimization-audit-report.md`

Begin the audit now. Be thorough, specific, and actionable in your findings.