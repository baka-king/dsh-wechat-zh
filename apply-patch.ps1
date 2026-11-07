param([switch]$Restore)

$ErrorActionPreference = "Stop"

$plugin = if ($env:DSH_WECHAT_ROUTER) { $env:DSH_WECHAT_ROUTER } else { Join-Path $env:USERPROFILE ".dsh\profiles\desktop\node_modules\dsh-wechat-plugin\dist\core\lib\router.js" }
$bak    = "$plugin.zh.bak"

if (-not (Test-Path $plugin)) {
    Write-Host "找不到插件文件：$plugin" -ForegroundColor Red
    Write-Host "请先在 DSH 侧栏「插件 → 添加插件」里装 dsh-wechat-plugin，重启后再运行本脚本。"
    exit 1
}

if ($Restore) {
    if (Test-Path $bak) {
        Copy-Item $bak $plugin -Force
        Write-Host "已回滚到补丁前版本。重启 DSH 生效。" -ForegroundColor Green
    } else {
        Write-Host "没有找到备份 $bak，无需回滚。" -ForegroundColor Yellow
    }
    exit 0
}

$src = Get-Content $plugin -Raw -Encoding UTF8

# 已经打过（不管是本脚本还是手工改的），直接退出
if ($src -match "command: '/list', args: ''") {
    Write-Host "已经打过补丁，无需重复操作。" -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path $bak)) {
    Copy-Item $plugin $bak
    Write-Host "已备份：$bak"
}

# --- 改动 1：中文别名 ---
$anchor = "const trimmed = text.trim();"
$insert = @'
    const trimmed = text.trim();
    // 中文别名：「菜单」= /list
    if (trimmed === '菜单')
        return { command: '/list', args: '' };
    if (/^菜单[ 　:：]/.test(trimmed))
        return { command: '/list', args: trimmed.slice(2).replace(/^[:\s：]+/, '').trim() };
'@

if ($src -notmatch [regex]::Escape($anchor)) {
    Write-Host "找不到锚点 1（splitCommand 里的 text.trim()）。上游可能改版了，请按 README 手动打补丁。" -ForegroundColor Red
    exit 1
}
$src = $src.Replace($anchor, $insert.TrimEnd())

# --- 改动 2：列表去掉短 id ---
$oldRow = '${String(index + 1)}. ${title}${when}${mark}  ${shortId(session.sessionId)}'
$newRow = '${String(index + 1)}. ${title}${when}${mark}'

if ($src -notmatch [regex]::Escape($oldRow)) {
    Write-Host "找不到锚点 2（会话列表那一行）。上游可能改版了，请按 README 手动打补丁。" -ForegroundColor Red
    exit 1
}
$src = $src.Replace($oldRow, $newRow)

# 无 BOM 写回
[IO.File]::WriteAllText($plugin, $src, (New-Object Text.UTF8Encoding($false)))
Write-Host "已打补丁。重启 DSH，在微信里发「菜单」验证。" -ForegroundColor Green
Write-Host "回滚：powershell -ExecutionPolicy Bypass -File .\apply-patch.ps1 -Restore"
