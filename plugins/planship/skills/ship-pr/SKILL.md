---
name: ship-pr
description: Ship the current branch through its full PR/MR life cycle on GitHub or GitLab, from pre-PR review to merged-and-synced. Use when the user wants a branch shipped, merged, or opened as a PR/MR — e.g. "ship it", "tạo PR".
---

Ship current branch end to end via platform CLI (`gh` or `glab`). Nine steps, run in order; steps 5 and 6 loop.

## 1. Pick the repo and platform

`git rev-parse --show-toplevel` at cwd. Succeeds → that's the repo root, proceed below. Fails with "not a git repository" → cwd is a container folder sitting above several repos (a multi-repo workspace, one folder per microservice) rather than a repo itself.

On that failure: list immediate subdirectories holding a `.git` (`find . -maxdepth 2 -name .git`, or PowerShell `Get-ChildItem -Directory -Depth 1 -Filter .git -Force`). Zero found → stop, tell Boss — nothing here is a git repo. One found → that's the repo, no question needed. Several found → Boss's request already naming a service (e.g. "ship payment-service") picks it by folder name, no question; otherwise list the candidate repo folders and ask Boss which one to ship. Every command in every step below then runs with that repo as cwd.

`git remote -v` inside the repo root. One platform in remotes → use it, no question. Remotes on **both** GitHub and GitLab → ask Boss which to ship through (list remotes found). Chosen platform decides CLI (`gh` for GitHub, `glab` for GitLab) and remote used for every push in later steps.

Shipping via GitLab → read [gitlab.md](gitlab.md) now for `glab` command mapping; steps below written in `gh` terms.

**CLI fallback:** chosen CLI failing for tool reasons — not installed, auth error, same command erroring twice — means switching to that platform's MCP tools for same operation (ToolSearch for github/gitlab tools). Neither CLI nor MCP works → stop and tell Boss.

Done when: exactly one repo root and exactly one platform + remote are locked in (Boss asked only when either was ambiguous).

## 2. One PR or several?

Skim branch against target base: `git log <base>..HEAD --oneline` and `git diff <base>...HEAD --stat`. One concern → step silent, move on. Diff mixing independent concerns (feature plus unrelated fix, two features, drive-by cleanup) → propose split to Boss: name each group with its files, let Boss pick one PR or several. Entangled groups (shared files, one needs other's code) ship together — stacked PRs are out of scope here.

On split: per group, branch off base (`git switch -c <group-branch> <base>`) and carry that group's changes over — cherry-pick when commits map one-to-one to groups, otherwise `git checkout <work-branch> -- <paths>` and commit. Then ship serially: run steps 3–8 to completion for one branch before starting next — later steps switch checkouts, so interleaving tangles them. Delete original mixed branch only after every group has merged.

Done when: Boss confirmed a single PR, or every group sits on its own branch and the groups together cover the whole original diff, with a shipping order agreed.

## 3. Self-review before opening

Skip this step entirely when `adaptive-plan-mode` already ran its Phase 8 review and Phase 9 verify on this exact diff, with no commits since — say so and move to step 4.

Invoke the `code-review` skill against `<base>` (base = the branch the PR will target). Fix every finding, or list the ones being waived and get Boss's explicit waive. This runs every time, even with reviewers and CI downstream: on a solo repo it is the only review the code will ever get, and on a team repo it saves the reviewer a round on an unpolished diff.

Then, if the diff touches runtime surface (product source — anything beyond docs/tests), run the `verify` skill on the final state of the branch. Verify comes after review on purpose: review findings produce fixes, and the fixes are part of what gets verified.

Done when: every review finding is fixed or Boss-waived, and `verify` passed on the final code (or the diff had no runtime surface, or the step was skipped per above).

## 4. Open the PR

Check for existing PR on branch before creating one — don't assume none: `gh pr list --head <branch> --state all --json number,state,url`.

- Nothing found → create one (`gh pr create`).
- Found, state OPEN → branch already shipped once, picked up more commits since; push them (`git push`), then skip straight to it with `gh pr view <num>`.
- Found, state MERGED → branch already merged; new commits need fresh PR against same base, not reopen. Tell Boss before creating one — usually means branch got reused instead of cut fresh.

Done when: you have a PR number, and it's open (not merged).

## 5. Wait for checks

```
gh pr checks <num> --watch --required
```

If it reports no checks found right after push, first tell apart two cases: repo has CI but checks haven't registered on GitHub's side yet (wait ~15s, retry — fresh push always lags), versus repo has no CI at all (no workflows in `.github/workflows/`, no `.gitlab-ci.yml`). Zero-CI repo → step is no-op: skip to step 6, note "no CI on this repo" at merge gate instead of retrying forever or reading empty result as pass. If `--required` errors on this repo, fall back to `gh pr checks <num> --watch` and only treat checks marked required in PR's branch protection as blocking.

If check fails: pull failing job's log (`gh run view --log-failed`), fix root cause, commit, push. Push re-enters this step — checks re-run on new commit.

If same check still red after 3 push-and-recheck rounds, stop — tell Boss which check, with log, instead of continuing to push blind fixes.

Done when: `gh pr checks --required` reports every required check green — or the repo was confirmed zero-CI.

## 6. Resolve review feedback

`gh pr view --json` has no `reviewThreads` field, its `comments` field misses inline review comments, and misses a review's own top-level `body` — read all three via GraphQL:

```
owner=$(gh repo view --json owner -q .owner.login)
repo=$(gh repo view --json name -q .name)
gh api graphql -f query='query($owner:String!,$repo:String!,$num:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$num){reviewDecision reviews(first:20){nodes{state author{login} body submittedAt}} reviewThreads(first:100){nodes{id isResolved comments(first:10){nodes{body author{login}}}}} comments(first:100){nodes{body author{login}}}}}}' -F owner="$owner" -F repo="$repo" -F num=<num>
```

Three distinct surfaces, all easy to miss individually: `reviewThreads` covers inline review comments (attached to diff line); `reviews` covers a review's own top-level `body` (summary text a reviewer — bot or human — writes when submitting review, separate from any inline threads it created); top-level `comments` covers plain PR conversation comments (not attached to review or line). Check all three. Review with findings but no matching thread and no top-level comment usually means bot review got silently downgraded — see [review-edge-cases.md](review-edge-cases.md).

For each unresolved thread requesting change: fix and push — this re-enters step 5, since fix invalidates last check run. For thread that's a question: reply, then resolve it yourself with `resolveReviewThread` mutation (skip resolve only if project's convention is that thread's opener resolves it — then leave it open and report it at merge gate instead of blocking on it here). For plain comment or review `body` requesting change or raising blocking question: treat it same as thread — fix and push, or reply — then leave `gh pr comment` acknowledging it (neither has resolve state to clear).

Done when: `reviewDecision` isn't `CHANGES_REQUESTED`, every unresolved thread, every review `body`, AND every plain PR comment is either addressed or explicitly deferred to the merge gate, and this state was reached without a push happening in between (a push means step 5 first).

## 7. Merge — stop and confirm

Check mergeability:

```
gh pr view <num> --json mergeable,mergeStateStatus
```

`mergeable` computed async — right after checks finish it can read `UNKNOWN`; wait few seconds, re-query rather than treating that as blocked.

- `mergeable: CONFLICTING` or `mergeStateStatus: DIRTY` → real content conflict. Tell Boss, ask: resolve it yourself, or Boss rebases manually. If Boss wants it resolved: `git fetch`, confirm it's genuine with `git merge-tree $(git merge-base origin/<base> <branch>) origin/<base> <branch>` (no `<<<<<<<` markers → clean auto-merge, merge and push), then `git merge origin/<base>` and hand-resolve any real markers. Rebuild/retest, then loop back to step 3 before pushing — hand-resolved conflict is unreviewed code same as any other diff.
- `mergeStateStatus: BEHIND` → branch out of date with base, no conflict. Run `gh pr update-branch <num>`, then go back to step 5.
- `mergeStateStatus: BLOCKED` → checks and content fine; branch protection rule isn't satisfied — almost always missing required approval (GitHub won't count your own approval on your own PR). Confirm with `gh api repos/{owner}/{repo}/branches/<base>/protection` (`required_pull_request_reviews.required_approving_review_count`); 404 "Branch not protected" there does NOT mean no rules — repo may use rulesets instead, check `gh api repos/{owner}/{repo}/rules/branches/<base>` (look for `pull_request` rule's `required_approving_review_count`). If repo has other collaborators, request one: `gh pr edit <num> --add-reviewer <user>`, then stop — wait for review rather than pushing further. If solo-maintainer repo and Boss is repo admin, `enforce_admins: false` means requirement can be bypassed with `--admin` on merge command below — surface this explicitly as part of merge confirmation, don't apply it silently.

Pick merge method: `gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`. One method enabled → use it. Several enabled → ask Boss which, unless project's CLAUDE.md already states convention.

Merging hard to reverse, touches shared state — always stop, get explicit go-ahead from Boss before running merge, even with everything green. Show PR's check/review/mergeable status *and* commits pushed during steps 5–6 (`gh pr view <num> --json commits`), so Boss is approving what actually shipped, not a green checkmark.

Once confirmed:

```
gh pr merge <num> --<method> --delete-branch
```

Add `--admin` only for BLOCKED-bypass case above, and only after Boss confirmed it specifically.

`--delete-branch` deletes branch both locally and on remote, switches local checkout to base branch as part of that — no separate branch cleanup needed.

Done when: Boss explicitly said to proceed, and the merge command exits 0.

## 8. Sync

On multi-PR split with groups still unshipped: after this sync, check out next group's branch, re-enter step 3.

```
git pull
```

Done when: `git status` shows the default branch, clean, up to date with origin — and no split group remains unshipped.

## 9. Improve this skill

See [`self-improve-after-running.md`](../self-improve-after-running.md).

Done when: the friction checklist there is checked — nothing to fix, or a diff was proposed and either applied or declined by Boss.
</content>
