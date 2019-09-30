  [CmdletBinding()]
  Param (
      [Parameter(Mandatory)]
      [string]
      $ProdRepo,

      [Parameter(Mandatory)]
      [string]
      $ProdRepoApiKey,

      [Parameter(Mandatory)]
      [string]
      $TestRepo
  )

  . .\ConvertTo-ChocoObject.ps1
  
  # get all of the packages from the test repo
  $testPkgs = choco list --source $TestRepo | Select-Object -Skip 1 | Select-Object -SkipLast 1 | ConvertTo-ChocoObject
  $prodPkgs = choco list --source $ProdRepo | Select-Object -Skip 1 | Select-Object -SkipLast 1 | ConvertTo-ChocoObject
  $tempPath = Join-Path -Path $env:TEMP -ChildPath ([GUID]::NewGuid()).GUID
  if ($null -eq $testPkgs) {
      Write-Host "Test repository appears to be empty. Nothing to push to production."
  }
  elseif ($null -eq $prodPkgs) {
      $pkgs = $testPkgs
  }
  else {
      $pkgs = Compare-Object -ReferenceObject $testpkgs -DifferenceObject $prodpkgs -Property name, version | Where-object SideIndicator -eq '<='
  }

  $pkgs | ForEach-Object {  
	Write-Verbose "Downloading package '$($_.name)' to '$tempPath'."
	choco download $_.name --no-progress --output-directory=$tempPath --source=$TestRepo --force
	# Create object to test against -CH
	$pkgTest = $_.name
      if ($LASTEXITCODE -eq 0) {
          $pkgPath = (Get-Item -Path (Join-Path -Path $tempPath -ChildPath '*.nupkg')).FullName
		  # Get list of all installed packages, convert to Chocolatey objects, and check if package is installed already - CH
		  $pkgList = choco list -lo | ConvertTo-ChocoObject
		  $pkgInstalled = 0

		  $pkgList | ForEach-Object {
			  if ($pkgTest -eq $_.name) {
				$pkgInstalled = 1
			  }
		  }
		  
          # Test installation of package locally - CH
		  If ($pkgInstalled -eq 1) {
			  Write-Verbose "Testing update of downloaded packages locally."
			  choco upgrade $pkgTest --source=$tempPath -y
		  }
		  else {
			  Write-Verbose "Testing install of downloaded packages locally."
			  choco install $pkgTest --source=$tempPath -y --force
		  }

          # If package testing is successful ...
          if ($LASTEXITCODE -eq 0) {
			  # Altered the package push as it could not deal with multiple packages before - CH
              $pkgPath | ForEach-Object {
                Write-Host "Pushing downloaded package '$(Split-Path -Path $_ -Leaf)' to production repository '$ProdRepo'."
                choco push $_ --source=$ProdRepo --api-key="5553ec8f-2846-3e01-8dc3-b5011965d26f" --force
              }
              if ($LASTEXITCODE -eq 0) {
                  Write-Verbose "Pushed package successfully."
              }
              else {
                  Write-Verbose "Could not push package."
              }
          }
          else {
              Write-Verbose "Package testing failed."
          }
      }
      else {
          Write-Verbose "Could not download package."
      }
  }

  Remove-Item -Path $tempPath -Force -Recurse