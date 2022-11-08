function Get-vCheckSetting
{
   param 
   (
      [string]$Module,
      [string]$Setting,
      $default
   )
   
   return $default
}

function Write-CustomOut ($Details) {
	$LogDate = Get-Date -Format "HH:mm:ss"
	Write-OutPut "[$($LogDate)] $Details"
}

function Add-ReportResource {
	param (
		$cid,
		$ResourceData,
		[ValidateSet("File", "SystemIcons", "Base64")]
		$Type = "File",
		$Used = $false
	)
	
	# If cid does not exist, add it
	if ($global:ReportResources.Keys -notcontains $cid) {
		$global:ReportResources.Add($cid, @{
			"Data" = ("{0}|{1}" -f $Type, $ResourceData);
			"Uses" = 0
		})
	}
	
	# Update uses count if $Used set (Should normally be incremented with Set-ReportResource)
	# Useful for things like headers where they are always required.
	if ($Used) {
		($global:ReportResources[$cid].Uses)++
	}
}

Export-ModuleMember -Function Get-vCheckSetting
Export-ModuleMember -Function Add-ReportResource
