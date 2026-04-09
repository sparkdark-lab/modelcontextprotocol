# AI File Tool Sandbox & Permissions Policy

## 1. Allowed Paths
- Only operate in: `d:/AI_Tools/Central_Repository/OLLAMA_SYSTEM/models`
- Exclude system/config/secrets (e.g., C:/Windows, /etc, .git, .ssh, browser profiles, DBs)

## 2. Access Tiers
- **Read-only**: Default for analysis/search
- **Read/Write**: Only in project folders, with explicit user approval & logging
- **Delete/Admin**: Only in `.trash` or temp, with explicit approval & logging

## 3. Escalation & Working Copies
- Sessions start read-only; AI must request escalation for write/delete
- Refactor/organize/cleanup: use working copies unless user requests in-place edits

## 4. Safe Write Pattern
- All writes use atomic replace: `.orig` backup, `.tmp` write, fsync, atomic rename
- If any step fails, original file is untouched

## 5. Delete/Destructive Ops
- Soft delete to `.trash` with timestamp
- Extra confirmation for recursive deletes, >50 files, or outside project path
- No auto-clean of user directories

## 6. Backups
- Before first write, create `.ai-backups/filename~YYYYMMDD-HHMM.ext`
- Keep at least N previous versions per file (configurable)

## 7. Operation Limits
- Hard caps: max file size, file count, directory depth
- If exceeded, summarize & ask user to confirm raising limits

## 8. Logging
- Log every write/rename/delete: timestamp, user/session, tool, paths, byte counts
- Provide a "what changed this session?" command

## 9. Editing Strategies
- Use structured diffs/patches for text/code edits
- Show summary & size before large changes; require confirmation
- For binary files, require explicit instruction & prefer scratch area

## 10. User Interaction
- Restate in plain language what will be touched, operations, and reversibility
- Require explicit consent for irreversible/wide-impact changes

## 11. Implementation Notes
- Use a dedicated file MCP server with path restrictions, tokens/roles, and logging
- Separate credentials for read, write, admin; only load as needed
- Keep server configs outside AI-writable areas
