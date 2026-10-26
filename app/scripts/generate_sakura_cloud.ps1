param([string]$AssetKey = 'sakura', [string]$Theme = '', [int]$Seed = 2141026, [string]$PromptOverride = '')
$ErrorActionPreference = 'Stop'
$settingsPath = Join-Path $env:APPDATA 'krita/ai_diffusion/settings.json'
$settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
$headers = @{ Authorization = "Bearer $($settings.access_token)" }
$api = 'https://api.interstice.cloud'
$account = Invoke-RestMethod "$api/user?plugin_version=1.53.0" -Headers $headers -TimeoutSec 30
Write-Output "Available credits: $($account.credits)"
if ($account.credits -le 0) { throw 'No cloud credits; no generation submitted.' }
$out = if($AssetKey -eq 'sakura'){Join-Path $PSScriptRoot '../design/sakura_ai'}else{Join-Path $PSScriptRoot "../design/frames_ai/$AssetKey"}
New-Item -ItemType Directory -Force -Path $out | Out-Null
$prompt = 'A single exquisite circular cherry blossom avatar frame, premium hand painted 2D fantasy mobile game UI asset, front view, centered perfect circular empty white opening. Thin elegant rose gold border. Asymmetric sakura branches around the OUTSIDE of the ring. Lush clusters of delicate five petal blush pink and ivory blossoms at upper right and lower left, fine golden stamens, dark plum twigs, tiny sage leaves, floating petals, luminous gold filigree, refined painterly anime illustration. Frame occupies 85 percent of square canvas, blank circular center 63 percent of canvas width. Isolated on pure white background, white empty center, no person, no portrait, no text.'
if($Theme){$prompt = "A single exquisite circular avatar frame, premium hand painted 2D fantasy mobile game UI asset, refined anime illustration, elegant organic silhouette, delicate ink outlines and painterly shading. $Theme. Front view, centered circular frame, ornate asymmetric decorations concentrated around the OUTSIDE of a thin ring. Balanced open negative space, readable at small size, no objects in the center. Frame occupies 85 percent of square canvas, large EMPTY pure white circular center occupies 63 percent of canvas width. Isolated on pure solid white background. No scenery, no person, no portrait, no text, no letters."}
if($PromptOverride){$prompt=$PromptOverride}
$workflow = @{
 kind='generate'; images=@{extent=@{input=@(1024,1024);initial=@(1024,1024);desired=@(1024,1024);target=@(1024,1024)}}
 models=@{checkpoint='zavychromaxl_v80.safetensors';version='sdxl';loras=@()}
 sampling=@{sampler='dpmpp_2m';scheduler='karras';cfg_scale=6.0;total_steps=28;seed=$Seed}
 conditioning=@{positive=$prompt;negative='3d render, plastic, photorealistic, thick bulky ring, portrait, face, person, text, watermark, logo, square frame, scenery, filled center, blurry, low quality';control=@();regions=@()}
 batch_count=1
}
$workflow | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath (Join-Path $out 'prompt.json') -Encoding utf8
$payload = @{input=@{workflow=$workflow;clientInfo='krita-ai-diffusion 1.53.0';options=@{useWebpCompression=$false}}} | ConvertTo-Json -Depth 20
$job=Invoke-RestMethod "$api/generate" -Method Post -Headers $headers -ContentType 'application/json' -Body $payload -TimeoutSec 60
$jobId=$job.id
Write-Output "Generation: $($job.status)"
$deadline=[DateTime]::UtcNow.AddMinutes(5)
while ($job.status.ToLower() -in @('in_queue','in_progress')) {
 if([DateTime]::UtcNow -gt $deadline){throw 'Generation timeout; check cloud job.'}
 Start-Sleep -Seconds 2
 $job=Invoke-RestMethod "$api/status/$jobId" -Method Post -Headers $headers -ContentType 'application/json' -Body '{}' -TimeoutSec 30
}
if($job.status.ToLower() -ne 'completed'){throw "Generation failed: $($job.error)"}
$images=$job.output.images
if($images.base64){$bytes=[Convert]::FromBase64String($images.base64)}else{$bytes=(Invoke-WebRequest $images.url -TimeoutSec 60).Content}
$start=[int]$images.offsets[0]
$end=if($images.offsets.Count -gt 1){[int]$images.offsets[1]}else{$bytes.Length}
$rawPath=Join-Path $out "$AssetKey-ai-output.bin"
[IO.File]::WriteAllBytes($rawPath,[byte[]]$bytes[$start..($end-1)])
Write-Output "Saved image: $rawPath"
