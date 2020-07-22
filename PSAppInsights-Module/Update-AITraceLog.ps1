#region Update-AITraceLog
#function to send an Applaction Insights Log Event using PSAppInsights
#----------------------------------------------------------------------------------------------------
function Update-AITraceLog() {
    <#
    .SYNOPSIS
    This function raises an event within application insights.

    .DESCRIPTION

    .NOTES
    AUTHOR  : Michael Zanatta
    CREATED : 
    VERSION : 0.1
          
    .INPUTS
        System.String[]

    .OUTPUTS
        System.Collections.Hashtable[]

    .PARAMETER Detail
    Initial log entry describing the action.

#>

    #Requires -version 5.1
    #Requires -Modules PSAppInsights
    #------------------------------------------------------------------------------------------------
    [cmdletbinding(
        DefaultParameterSetName = 'Standard'
    )]
    param (
        [parameter(Mandatory,ParameterSetName = 'Standard', Position = 0, ValueFromPipeline)]
        [parameter(Mandatory,ParameterSetName = 'ExpandedHashTable', Position = 0, ValueFromPipeline)]
        [parameter(Mandatory,ParameterSetName = 'ExpandedObject', Position = 0, ValueFromPipeline)]
        [parameter(Mandatory,ParameterSetName = 'Error', Position = 0, ValueFromPipeline)]
        [String]
        $detail,
        [parameter(ParameterSetName = 'Standard', Position = 1)]
        [parameter(ParameterSetName = 'ExpandedHashTable', Position = 1)]
        [System.Collections.Hashtable]
        $customHashTable,
        [parameter(ParameterSetName = 'Standard', Position = 1)]
        [parameter(ParameterSetName = 'ExpandedObject', Position = 1)]
        [Object]
        $customObject,
        [parameter(ParameterSetName = 'Standard', Position = 1)]
        [parameter(ParameterSetName = 'Error', Position = 1)]
        [System.Collections.Hashtable]
        $errorDetails,
        [parameter(Position = 2, ParameterSetName = 'Standard')]
        [parameter(Position = 2, ParameterSetName = 'ExpandedHashTable')]
        [parameter(Position = 2, ParameterSetName = 'ExpandedObject')]
        [parameter(Position = 2, ParameterSetName = 'Error')]
        [string]
        [ValidateSet("Information", "Warning", "Error", "Verbose", "Debug")]
        $type="Information",
        [parameter(Position = 3, ParameterSetName = 'Standard')]
        [parameter(Position = 3, ParameterSetName = 'ExpandedHashTable')]
        [parameter(Position = 3, ParameterSetName = 'ExpandedObject')]
        [parameter(Position = 3, ParameterSetName = 'Error')]
        [String]
        $InstrumentationKey = $AppInsightsInstrumentationKey,        
        [parameter(Position = 4, ParameterSetName = 'Standard')]
        [parameter(Position = 4, ParameterSetName = 'ExpandedHashTable')]
        [parameter(Position = 4, ParameterSetName = 'ExpandedObject')]
        [parameter(Position = 4, ParameterSetName = 'Error')]
        [String]
        $ResourceName = $ScriptName,
        [parameter(Position = 5, ParameterSetName = 'Standard')]
        [parameter(Position = 5, ParameterSetName = 'ExpandedHashTable')]
        [parameter(Position = 5, ParameterSetName = 'ExpandedObject')]
        [parameter(Position = 5, ParameterSetName = 'Error')]
        [Switch]
        $Flush,        
        [parameter(Position = 6, ParameterSetName = 'Standard')]
        [parameter(Position = 6, ParameterSetName = 'ExpandedHashTable')]
        [parameter(Position = 6, ParameterSetName = 'ExpandedObject')]
        [parameter(Position = 6, ParameterSetName = 'Error')]
        [Switch]
        $pesterShouldReturnParams
    )

    #Use the begin block to retrieve the component from the call stack, format the output and check if the logfile needs to be rolled over
    begin {

        # Throw an Error if the ResourceName parameter is missing
        if (-not($ResourceName)) {
            Throw "Missing -ResourceName Parameter or Missing `$ScriptName variable."
        }
        
        # Validate that New-AIClient has been setup.
        # If there is no InstrumentationKey in the Global Object used by PSAppInsights, however one was provided by the module:
        # Attempt to Create a connection to App Insights.
        if (-not( $Global:AISingleton.Client.InstrumentationKey ) -and (($InstrumentationKey) -or ($AppInsightsInstrumentationKey))) {

            # Create the Client with the InstrumentationKey
            $null = New-AIClient -InstrumentationKey $InstrumentationKey

        }

        #Retrieve the calling function using the call stack
        $callStack = Get-PSCallStack

        #Enumerate the members of the call stack to find the caller
        $component = $(
                        if ($callstack[1].Command -eq "Update-AITraceLog") { Write-Output $callstack[2].Command }
                        else { Write-Output $callstack[1].Command}
                      )

    }
    process {
        # Capture the Event Date
        $EventDate = Get-Date

        # AI Message
        $MessageToSend = "$component`t$detail"

        # Cmdlet Parameters
        $params = @{
            Message = $MessageToSend
            FullStack = $true
            SeverityLevel = [Microsoft.ApplicationInsights.DataContracts.SeverityLevel]::Information
            Properties = @{
                ResourceName = $ResourceName
                DateTime = $EventDate
                Component = $component
            }         
        }

        # Cmdlet Name
        $cmdletToExecute = "Send-AITrace"

        # If the customItems Parameter was specified, add the key/values to the event. Otherwise write the details
        if ($customHashTable) {
            # Dynamically Add the Hashtable Properties to the HashTable
            $customHashTable.Keys | ForEach-Object {
                $params.Properties.Add( "custom_{0}" -f $_, $customHashTable[$_])
            }
        }
        # If the customObject Parameter was specified, add the known properites to the event. Otherwise seralize the object as JSON
        if ($customObject) {
            # Dynamically Add the properties of the object to the HashTable
            $customObject | Get-Member -MemberType Property,NoteProperty | ForEach-Object {
                $params.Properties.Add( "custom_{0}" -f $_.Name, $customHashTable."$_")
            }            
        }

        switch ($type) {
            "Verbose" {                
                # Set the Event Severity Level
                $params.SeverityLevel = [Microsoft.ApplicationInsights.DataContracts.SeverityLevel]::Verbose
                # Print a Verbose Message
                Write-Verbose $MessageToSend
            }
            "Warning" {
                # Set the Event Severity Level
                $params.SeverityLevel = [Microsoft.ApplicationInsights.DataContracts.SeverityLevel]::Warning
                # Print a Warning
                Write-Warning $MessageToSend
            }
            "Error" {
                # Set the Event Severity Level
                $params.SeverityLevel = [Microsoft.ApplicationInsights.DataContracts.SeverityLevel]::Critical

                # If -ErrorDetails was specified, then it will raise an exception, rather then an event.
                # Therefore will need to change the calling cmdlet.
                if ($errorDetails) {

                    #
                    # Change the Parameters and cmdlet 

                    # Change the Cmdlet to call
                    $cmdletToExecute = "Send-AIException"
                    # Redefine our Parameters, according to Send-AIException                
                    $params = @{
                        ErrorInfo = $MessageToSend
                        Properties = @{
                            ResourceName = $ResourceName
                            DateTime = $EventDate
                            Component = $component                            
                        }
                    }
                    # Add Each of the Error Details to the Properties
                    $errorDetails.Keys | ForEach-Object { $params.Properties.Add($_, $errorDetails[$_]) }

                }

                # Write the Error
                Write-Error $MessageToSend
            }
            "Debug" {
                # Set the Event Severity Level
                $params.SeverityLevel = [Microsoft.ApplicationInsights.DataContracts.SeverityLevel]::Verbose                
                # Print the Debug
                Write-Debug $MessageToSend
            }
            "Information" {
                # Print some Information
                Write-Information $MessageToSend
            }
        }

        # Raise the Event/Exception
        try {
            # Run the PowerShell String and Splat the Parameters in.
            $null = & $cmdletToExecute @params
        } Catch {
            Write-Error $_
        }

        # If the Parameter "-pesterShouldReturnParams" is called, return the parameters
        if ($pesterShouldReturnParams) { Write-Output $params }        

    }
}
#endregion Update-AITraceLog