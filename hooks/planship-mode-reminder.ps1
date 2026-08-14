# planship-mode-reminder — UserPromptSubmit hook. Re-injects the current
# planship model mode every turn, since skill/agent instructions are static
# text and can't read state on their own. Silent when mode is "normal"
# (planship's baseline behavior, nothing to override) or the state file is
# missing. Silent-fails on any error; never blocks the prompt.
# mode→model/effort mapping mirrors commands/planship-mode.md — keep both in sync.

try {
    $modeFile = "$HOME\.claude\planship\mode.txt"
    if (-not (Test-Path $modeFile)) { exit 0 }

    $mode = (Get-Content $modeFile -Raw -ErrorAction Stop).Trim()
    if ($mode -eq '' -or $mode -eq 'normal') { exit 0 }

    $modelLine = switch ($mode) {
        'economy' { "model 'sonnet', default effort" }
        'premium' { "model 'opus', effort/thinking pushed to max" }
        default   { $null }
    }
    if (-not $modelLine) { exit 0 }

    $ctx = "planship mode is '$mode'. When spawning adaptive-plan-mode's Phase 6 plan-review agent (agentType 'Plan') or the 'planship:oryna' agent, override its model to $modelLine instead of the file's default. Nothing else in planship changes for this mode."

    $out = [PSCustomObject]@{
        hookSpecificOutput = [PSCustomObject]@{
            hookEventName     = "UserPromptSubmit"
            additionalContext = $ctx
        }
    }
    $out | ConvertTo-Json -Compress
    exit 0
} catch {
    exit 0
}
