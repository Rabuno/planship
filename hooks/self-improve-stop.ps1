# self-improve-stop — Stop hook. Fires once per turn (guarded by the
# harness's own stop_hook_active flag, not a homemade marker, to avoid an
# infinite block loop) and asks the agent to self-check the turn just run
# for friction against any planship skill/agent, not just the ones that
# name self-improve-after-running.md as an explicit step. Silent no-op if
# nothing surfaces or the hook errors; never blocks a stop twice in a row.

try {
    $raw = [Console]::In.ReadToEnd()
    $payload = $raw | ConvertFrom-Json -ErrorAction Stop

    if ($payload.stop_hook_active -eq $true) { exit 0 }

    $reason = "Self-check (silent): any friction with planship skills/agents run this session (adaptive-plan-mode, ship-pr, user-tester, grilling, oryna)? No -> stay silent, no report. Yes -> read skills/self-improve-after-running.md, propose a diff, wait for approval."

    $out = [PSCustomObject]@{
        decision = "block"
        reason   = $reason
    }
    $out | ConvertTo-Json -Compress
    exit 0
} catch {
    exit 0
}
