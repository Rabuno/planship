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

    $reason = "Truoc khi dung: xet phien vua roi co friction nao khong -- Boss sua/chinh 1 hanh dong hay quyet dinh, mot buoc skill khong khop thuc te, mot mo ho bi tu quyet thay vi hoi -- CHI voi cac skill/agent thuoc plugin planship (adaptive-plan-mode, ship-pr, user-tester, grilling, oryna) da chay trong phien. Bo qua moi skill khac khong thuoc plugin planship, du co friction gi voi no. Khong co friction that voi planship -> im lang, ket thuc binh thuong, khong can bao cao gi. Co -> doc skills/self-improve-after-running.md, de xuat diff cu the cho skill planship lien quan, cho Boss xem, chi ap dung khi Boss duyet."

    $out = [PSCustomObject]@{
        decision = "block"
        reason   = $reason
    }
    $out | ConvertTo-Json -Compress
    exit 0
} catch {
    exit 0
}
