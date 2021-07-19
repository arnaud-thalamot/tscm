[CmdletBinding()]
[OutputType([int])]
Param
(

        [Parameter(Mandatory=$True,Position=0)]
			[string]$operationType,
        [Parameter(Mandatory=$True,Position=1)]
			[string]$vmName,
		[Parameter(Mandatory=$False,Position=2)]
			[string]$vmOS
		
)

function ValidateParameters {
	Param ([string]$opType)

	switch ($opType) 
	{
		"reg" {Write-Log "Operation is REGISTER a new client." $LogFile Info}
		"del" {Write-Log "Operation is DELETE an existing client." $LogFile Info}
		"col" {Write-Log "Operation is EXECUTE COLLECTORS on a client." $LogFile Info}
		"rep" {Write-Log "Operation is GENERATE REPORT on a client." $LogFile Info}
		default {Write-Log "Operation cannot be determined." $LogFile Info
		exit 1}
}
	
	Write-Output $c

}

#Find current path
$RootDirectory = $PSScriptRoot

#Load functions
. $RootDirectory\Libraries\Function-Write-Log.ps1

#Set Log file and Path variables
$LogFile = "$RootDirectory\Log\TSCM_wrapper.log"

Write-Log "Startup of TSCM WRAPPER script." $LogFile Info
Write-Log "Validating parameters." $LogFile Info
ValidateParameters($operationType)
Write-Log "Script was called to perform $operationType for $vmName." $LogFile Info

Write-Log "End of TSCM WRAPPER script." $LogFile Info

exit 0