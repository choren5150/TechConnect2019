node {
 powershell '''
  $temp = Join-Path -Path $env:TEMP -ChildPath ([GUID]::NewGuid()).Guid
  $null = New-Item -Path $temp -ItemType Directory
  Write-Output "Created temporary directory '$temp'."
  ($env:P_PKG_LIST).split(';') | ForEach-Object {
      choco download $_ --no-progress --internalize --force --internalize-all-urls --append-use-original-location --output-directory=$temp --source='https://chocolatey.org/api/v2/'
      if ($LASTEXITCODE -eq 0) {
          $package = (Get-Item -Path (Join-Path -Path $temp -ChildPath "$_*.nupkg")).fullname
          $package | ForEach-Object {
            choco push $_ --source "$($env:P_DST_URL)" --api-key "$($env:P_API_KEY)" --force
          }
      }
      else {
          Write-Output "Failed to download package '$_'"
      }
  }
  Remove-Item -Path $temp -Force -Recurse
 '''
}