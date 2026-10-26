$ErrorActionPreference='Stop'
$themes=[ordered]@{
 title_night_owl='an elegant little owl with lavender feathers and ivory eyes, crescent moon crest, silver filigree and tiny stars, midnight plum enamel'
 title_early_bird='a graceful swallow with outstretched wings above a small sunrise, champagne gold filigree and peach enamel, warm morning light'
 title_ice_guardian='a luminous six pointed ice crystal crest with silver laurel leaves, pale blue enamel and ivory ribbon tails'
 title_flame_keeper='a stylized warm orange flame nestled in small gold phoenix wings, ruby enamel and bronze filigree'
 title_ocean_soul='a turquoise ocean wave with an ivory pearl and small seashell, flowing gold filigree and aquamarine enamel'
 title_crowned='a refined ruby set golden crown inside a golden laurel crest, crimson ribbon tails and champagne highlights'
 badge_streak='a vivid orange focus flame inside a bronze and gold medal, small golden laurel sprigs and warm terracotta ribbon tails'
 badge_sessions='an emerald shield containing a clear gold checkmark, sculpted illustrated laurel leaves and sage ribbon tails'
 badge_hours='a delicate ivory and gold hourglass with golden sand inside a blue enamel medallion, silver laurel leaves and teal ribbon tails'
}
$i=0
foreach($e in $themes.GetEnumerator()){
 $i++
 $target=Join-Path $PSScriptRoot "../design/frames_ai/$($e.Key)/$($e.Key)-ai-output.bin"
 if(Test-Path -LiteralPath $target){continue}
 $prompt="A single exquisite heraldic achievement emblem, $($e.Value). Premium 2D hand painted fantasy mobile game inventory icon. Confident delicate ink outlines, refined painterly highlights, rich harmonious colors, elegant compact silhouette, beautifully illustrated details readable at small sizes. One centered standalone emblem occupying 75 percent of a square canvas, all decorative tips fully inside image with generous clean margin. Isolated cutout on PURE SOLID WHITE background. No scene, no background gradient, no lettering, no words, no numbers, no watermark. Flat front view, illustration, not a 3D render."
 Write-Output "[$i/9] $($e.Key)"
 & "$PSScriptRoot/generate_sakura_cloud.ps1" -AssetKey $e.Key -PromptOverride $prompt -Seed (2211000+$i)
}
