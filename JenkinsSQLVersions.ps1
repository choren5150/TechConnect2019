#Author: Chris Horen
#Purpose: Queries all MSSQL servers provided in the script to gather the Major Version, Product Level, Product Update Level, Product Version and Edition into a table through Jenkins that is sent to OIT-RSS-Systems@ucdenver.edu

[CmdletBinding()]
Param (
    [Parameter(Mandatory)]
    [string]
    $User,
 
    [Parameter(Mandatory)]
    [string]
    $Pass
)

Import-Module SqlServer
$folderloc = "C:\ScriptResults"
$filename = "SQLServerVersions.csv"

$remotePass = ConvertTo-SecureString $Pass -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($User, $remotePass)

$query= @"
     SELECT CASE 
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '8%' THEN 'SQL 2000'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '9%' THEN 'SQL 2005'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '10.0%' THEN 'SQL 2008'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '10.5%' THEN 'SQL 2008 R2'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '11%' THEN 'SQL 2012'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '12%' THEN 'SQL 2014'
     WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '13%' THEN 'SQL 2016'
	 WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion')) like '14%' THEN 'SQL 2017' 	 
     ELSE 'unknown'
  END AS 'Major Version',
  SERVERPROPERTY('ProductLevel') AS 'Product Level',
  SERVERPROPERTY('ProductUpdateLevel') AS 'Product Update Level',
  SERVERPROPERTY('Edition') AS 'Edition',
  SERVERPROPERTY('ProductVersion') AS 'Product Version';
"@

function QuerySQLServers {
	Param(
		[Parameter(Mandatory)]
		[ValidateNotNull()]
		[System.Management.Automation.PSCredential]
		$login
	)
	
    $sqlServers = "Valhalla","M-D-ES-DB","M-D-IENS-DB","M-D-IS-DB","M-O-ES-DB","M-O-IENS-DB","M-O-IS-DB","Caravan","Caravan-Dev","SMSKDB", "PRSSDB250"

    foreach ($i in $sqlServers){
        switch ($i) 
        {
            valhalla {
                Invoke-Command -ComputerName $i -Credential $login -ScriptBlock { Invoke-Sqlcmd -Query $args[0] -QueryTimeout 3 -ServerInstance "valhalla\Test" } -ArgumentList $query 
                }
            caravan-dev {
                Invoke-Command -ComputerName $i -Credential $login -ScriptBlock { Invoke-Sqlcmd -Query $args[0] -QueryTimeout 3 -ServerInstance "caravan-dev\caravanDevsql" } -ArgumentList $query
                }
            caravan {
                Invoke-Command -ComputerName $i -Credential $login -ScriptBlock { Invoke-Sqlcmd -Query $args[0] -QueryTimeout 3 -ServerInstance "caravan\caravan" } -ArgumentList $query
                }
            smskdb {
                Invoke-Command -ComputerName $i -Credential $login -ScriptBlock { Invoke-Sqlcmd -Query $args[0] -QueryTimeout 3 -ServerInstance "smskdb\smskdb" } -ArgumentList $query
                }
            default {
                Invoke-Command -ComputerName $i -Credential $login -ScriptBlock { Invoke-Sqlcmd -Query $args[0] -QueryTimeout 3 -ServerInstance $i } -ArgumentList $query
                }
        } 
    }

}

New-Item -ItemType Directory -Force -Path $folderloc
New-Item -ItemType File -Force -Path $folderloc\$filename
QuerySQLServers -login $credential | Select-Object -Property @{n='Server';e={$_.PSComputerName}}, 'Major Version', 'Product Level', 'Product Update Level', 'Product Version', 'Edition' | export-csv $folderloc\$filename -NoTypeInformation