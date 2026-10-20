param([Parameter(Mandatory=$true)][string]$BitPath)
$ErrorActionPreference='Stop'
$expected='60AE6B971CE1F9ED09D76BEC14CF88DFC25CDFE7CBBEBE5DD9FC070115B812CE'
$file=Get-Item -LiteralPath $BitPath
if($file.PSIsContainer){throw 'BitPath must be a file'}
$actual=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
$result=[ordered]@{
    File=$file.FullName
    Bytes=$file.Length
    SHA256=$actual
    ExpectedC11312=$expected
    MatchesC11312=($actual -eq $expected -and $file.Length -eq 634280)
    Scope='Read-only local file check; does not verify configuration inside the FPGA.'
}
$result | ConvertTo-Json
if(!$result.MatchesC11312){exit 1}
