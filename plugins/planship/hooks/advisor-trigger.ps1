# advisor-trigger — UserPromptSubmit hook. When the prompt contains the
# "oryna" keyword (any case), instructs the model to launch the oryna
# advisor agent instead of answering inline.
# Silent-fails on any error; never blocks the prompt.

try {
    $stdin = [Console]::In.ReadToEnd()
    $payload = $stdin | ConvertFrom-Json -ErrorAction Stop
    $prompt = ($payload.prompt -join ' ')

    if ($prompt -notmatch '(?i)\boryna\b') { exit 0 }

    $ctx = "Keyword trigger: the user summoned the oryna advisor. If this prompt is instead about editing/configuring the oryna setup itself (its agent file, this hook, or its settings.json entry) rather than asking it for a decision, this is a false trigger - handle the prompt normally and do not launch the agent. Otherwise: launch the Agent tool with subagent_type 'planship:oryna' now (oryna now ships from the planship plugin). Pass it the user's decision/question verbatim, plus the minimum context it needs: relevant file paths, constraints, options already on the table, and what the user is currently leaning toward (labeled as such). Do NOT answer the decision yourself and do NOT pre-judge the options in the prompt you send. Relay the advisor's full verdict back to the user when it returns."

    $out = [PSCustomObject]@{
        systemMessage      = [char]0xD83E + [char]0xDDD3 + " Oryna summoned - researching before verdict."
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
