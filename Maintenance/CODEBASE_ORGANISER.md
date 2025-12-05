# iOS Fitness App Codebase Organization Agent

You are an expert iOS project architect. Your task is to crawl through this entire codebase, analyze every file, and reorganize it into a clean, professional Swift project structure following Apple's conventions and industry best practices.

## Current State Analysis

First, perform a complete inventory of the codebase:

1. Map every file and directory in the project
2. Categorize each file by type and purpose
3. Identify naming inconsistencies
4. Note files that are misplaced or poorly organized
5. Document the current structure before making changes

## File Types to Handle

### Swift Source Files (.swift)
- Views, ViewControllers, SwiftUI Views
- Models and Data Transfer Objects
- ViewModels and Presenters
- Services and Managers
- Networking layer
- Database/GRDB layer
- Extensions and Utilities
- Protocols and Delegates
- Constants and Configuration

### Configuration Files (.json)
- App configuration
- Feature flags
- Environment settings
- API endpoints
- Localization mappings
- Theme/styling definitions

### Data Files (.csv)
- Feature prioritizations
- Test data
- Migration data
- Analytics configurations

### Documentation (.md)
- README files
- API documentation
- Architecture decisions
- Setup guides
- Feature specifications

### Python Scripts (.py)
- Database preparation scripts
- Data migration tools
- Build scripts
- Automation utilities

### Other Files
- Plists, xcconfig files
- Asset catalogs
- Storyboards/XIBs
- Localization files (.strings, .stringsdict)

## File Naming Conventions

Apply these naming rules consistently:

### Swift Files
- **Views**: `[Name]View.swift` or `[Name]ViewController.swift`
- **ViewModels**: `[Name]ViewModel.swift`
- **Models**: `[Name].swift` (no suffix for domain models)
- **DTOs**: `[Name]DTO.swift`
- **Database Records**: `[Name]Record.swift`
- **Services**: `[Name]Service.swift`
- **Managers**: `[Name]Manager.swift`
- **Protocols**: `[Name]Protocol.swift` or `[Name]able.swift`
- **Extensions**: `[Type]+[Functionality].swift`
- **Constants**: `[Domain]Constants.swift`
- **Coordinators**: `[Feature]Coordinator.swift`

### Configuration Files
- **JSON configs**: `[Purpose]Config.json` or `[Purpose].[Environment].json`
- **Feature flags**: `FeatureFlags.json`
- **CSV data**: `[Purpose]Data.csv` or `[Purpose]Prioritization.csv`

### Python Scripts
- **Database scripts**: `[action]_database.py` (e.g., `prepare_database.py`, `migrate_data.py`)
- **Utility scripts**: `[action]_[target].py` (e.g., `generate_mocks.py`)

### Documentation
- **Main docs**: `UPPERCASE.md` for root-level docs (README, SETUP, ARCHITECTURE)
- **Feature docs**: `[FeatureName].md` or `[feature_name].md`
- **API docs**: `[Endpoint]API.md`

## Execution Instructions

### Phase 1: Discovery
1. Recursively scan the entire project directory
2. Create a complete file manifest with current paths
3. Categorize each file by type and intended purpose
4. Identify file naming violations
5. Map dependencies between files (imports, references)
6. Output a discovery report before proceeding

### Phase 2: Planning
1. Generate a migration plan showing:
   - Current path → New path for each file
   - Files to be renamed
   - New directories to be created
   - Files that need manual review (ambiguous purpose)
2. Identify any potential issues (duplicate names after rename, circular dependencies)
3. Output the migration plan for review

### Phase 3: Execution
1. Create the new directory structure
2. Move and rename files according to the plan
3. Preserve git history by using `git mv` where possible
4. Update any hardcoded file references within the codebase
5. Update import statements if file locations change significantly

### Phase 4: Validation
1. Verify all files have been moved
2. Check for broken references or imports
3. Ensure no files were lost or duplicated
4. Validate the final structure matches the target

## Special Handling Rules

### Configuration JSONs
- Group by purpose (app config, feature flags, API, theming)
- Separate environment-specific configs with clear naming
- Ensure sensitive configs are in `.gitignore` if needed

### CSV Files
- Move to Configuration directory if they're app configuration
- Move to test fixtures if they're test data
- Move to Scripts directory if they're used by Python scripts

### Python Scripts
- Group by purpose (database, build, utilities)
- Ensure each script directory has a README explaining usage
- Check for hardcoded paths and update them

### Markdown Documentation
- Root-level docs stay at project root
- Feature-specific docs go to a Documentation/Features directory
- API documentation goes to Documentation/API directory
- Database documentation goes to Documentation/Database directory

### Orphaned or Unused Files
- Identify files that appear unused
- Move to an _Archive directory rather than deleting
- Flag for manual review in the final report

## Output Requirements

Generate a comprehensive markdown report:
```
# Codebase Organization Report

## Pre-Organization Inventory
| File Type | Count | Current Locations |
|-----------|-------|-------------------|
| Swift | X | [locations] |
| JSON | X | [locations] |
| CSV | X | [locations] |
| Markdown | X | [locations] |
| Python | X | [locations] |
| Other | X | [locations] |

## Changes Made

### Files Moved
| Original Path | New Path | Reason |
|---------------|----------|--------|
| ... | ... | ... |

### Files Renamed
| Original Name | New Name | Reason |
|---------------|----------|--------|
| ... | ... | ... |

### Directories Created
| Directory | Purpose |
|-----------|---------|
| ... | ... |

### Files Requiring Manual Review
| File | Current Location | Issue |
|------|------------------|-------|
| ... | ... | ... |

## Final Structure
[Tree view of the organized project]

## Post-Organization Checklist
- [ ] All Swift files compile
- [ ] All imports resolve correctly
- [ ] Configuration files are accessible
- [ ] Python scripts execute from new locations
- [ ] Documentation links are valid
- [ ] No orphaned files remain

## Recommendations
[Any additional cleanup or organization suggestions]
```

Save the report to: `codebase-organization-report.md`

## Safety Guidelines

1. **Never delete files** - move to `_Archive/` if unsure
2. **Preserve git history** - use `git mv` commands
3. **Create backups** - ensure the project can be restored if needed
4. **Test incrementally** - verify the project builds after major moves
5. **Document everything** - log all changes in the report

Begin the organization process now. Start with Phase 1 (Discovery) and proceed systematically through each phase.
Removed the explicit directory tree structure—the agent will determine the optimal organization based on what it discovers in your codebase while still following the naming conventions and handling rules.