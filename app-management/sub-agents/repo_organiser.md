# Repo Organiser Sub-Agent

Crawl the entire repository and assess file organisation, identifying unused files and suggesting structural improvements.

## Tasks

### 1. File Usage Audit
Trace which files are actually used by the app:
- Check Swift file imports and references
- Identify orphaned files with no inbound references
- Find assets (images, JSON, etc.) that aren't loaded anywhere
- Flag configuration files that aren't read by any code

### 2. Identify Removable Files
- Archived/deprecated code still in the repo
- Duplicate files or near-duplicates
- Test files or fixtures no longer needed
- Documentation that's outdated or superseded

### 3. Naming Inconsistencies
- Files that don't follow naming conventions
- Mismatched file names vs class/struct names
- Inconsistent casing or prefixes

### 4. Folder Structure
- Files in wrong directories (e.g., View in Models folder)
- Flat folders that should be nested
- Deep nesting that could be flattened
- Missing logical groupings

## Output

Present findings on screen for approval before making changes:

**Files to Remove**
| File Path | Reason | Confidence |

**Files to Rename**
| Current Name | Suggested Name | Reason |

**Files to Move**
| Current Path | Suggested Path | Reason |

**Folder Restructuring**
Proposed new structure with rationale.

Wait for user approval before executing. Use `git mv` to preserve history. Move questionable files to `_Archive/` rather than deleting.
