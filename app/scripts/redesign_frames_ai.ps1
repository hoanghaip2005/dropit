$ErrorActionPreference='Stop'
$themes=[ordered]@{
 frame_leaf='Enchanted forest laurel, fine antique gold vine ring, flowing emerald and sage leaves, small ivory woodland blossoms, curling tendrils, jade dew drops, lush foliage clusters lower left and upper right, elegant botanical jewelry'
 frame_sunset='Celestial sunset, slender copper and gold ring, flowing amber clouds and curling ribbons, a small ornate sun crest at the top, warm coral and peach accents, tapered golden sun rays, ornamental fantasy filigree'
 frame_galaxy='Moonlit celestial garden, thin silver and violet ring, ornate crescent moon at upper left, asymmetrical amethyst crystal clusters lower right, flowing indigo silk ribbons, delicate silver stars and constellation ornaments, lavender and deep plum palette'
 frame_frost='Winter ice fairy, thin engraved silver ring, asymmetric clusters of sharp luminous pale blue ice crystals and ornate snowflakes, curling frosty silver vines, pale turquoise ribbon tails, elegant cold blue and ivory palette'
 frame_phoenix='Fire phoenix regalia, delicate bronze and gold ring, stylized sweeping scarlet and orange phoenix feathers curling around the outside, dramatic wing flourish at upper right and flame-shaped feather cluster lower left, ruby drops, warm golden highlights, no full bird'
 frame_tidal='Ocean pearl regalia, fine turquoise and gold ring, curling stylized sea waves outside the ring, asymmetrical small seashell and pearl clusters, elegant coral branches, flowing teal ribbons and aquamarine drops, refined seafoam and ivory highlights'
 frame_cyber='Arcane technology, thin dark navy and polished silver segmented ring, elegant asymmetric angular armor fins, cyan illuminated circuit engravings, floating small electric blue crystal ornaments, sharp sleek silhouette, illustrated science fantasy game inventory frame'
 frame_royal='Royal crimson regalia, fine ornate gold ring with scrollwork, small elegant jeweled crown on top, asymmetric golden laurel leaves and curled deep crimson silk ribbons at lower corners, ruby gemstones and champagne highlights, dignified luxurious illustration'
}
$i=0
foreach($entry in $themes.GetEnumerator()){
 $i++
 $target=Join-Path $PSScriptRoot "../design/frames_ai/$($entry.Key)/$($entry.Key)-ai-output.bin"
 if(Test-Path -LiteralPath $target){Write-Output "Already generated: $($entry.Key)";continue}
 Write-Output "[$i/8] $($entry.Key)"
 & "$PSScriptRoot/generate_sakura_cloud.ps1" -AssetKey $entry.Key -Theme $entry.Value -Seed (2141026+$i)
}
