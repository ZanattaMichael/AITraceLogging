Describe "Update-AITraceLog Unit Tests" {

    BeforeAll {

        # Dot Source the Function into Memory
        . .\Update-AITraceLog.ps1

        # Load the Stub of the Function

        # If Log-ApplicationInsightsEvent dosen't need to be loaded.
        # So let's just create a stub
        function Log-ApplicationInsightsEvent {}

        # Setup Stream Preference
        $InformationPreference = "Continue"
        $WarningPreference = "Continue"
        $VerbosePreference = "Continue"
        $DebugPreference = "Continue"
        # Set Global Parameter that won't change during the test
        $AppInsightsInstrumentationKey = "TEST"
        $ScriptName = "TEST SCRIPTNAME"
    }

    #
    # Functions
    #

    # Test the Standard Input
    function Test-StandardInput() {
        param($type, $expectedResult)

        #
        # Arrange

        # Get the Asserted Cmdlet
        $assertedCmdlet = $null
        Switch ($type) {
            "information"   { $assertedCmdlet = "Write-Information" }
            "error"         { $assertedCmdlet = "Write-Error" }
            "warning"       { $assertedCmdlet = "Write-Warning" }
            "debug"         { $assertedCmdlet = "Write-Debug" }
            "verbose"       { $assertedCmdlet = "Write-Verbose" }
        }

        # Setup Mocks
        Mock Log-ApplicationInsightsEvent -MockWith {}
        Mock Write-Information {}
        Mock Write-Warning {}
        Mock Write-Error {}
        Mock Write-Verbose {}
        Mock Write-Debug {}

        #
        # Act
        $result = Update-AITraceLog -detail "TEST" -type $type -pesterShouldReturnParams

        #
        # Assert

        it "Should call '$assertedCmdlet' with the expected result" {
            Assert-MockCalled $assertedCmdlet -Times $expectedResult
        }
        it "Should have Standard ParameterSet" {
            $result.InstrumentationKey | Should be $AppInsightsInstrumentationKey
            $result.EventName | Should be $ScriptName
            $result.EventDictionary.ResourceName | Should be $ScriptName
            $result.EventDictionary.EventType | Should be $type
            $result.EventDictionary.DateTimeLogged | Should not be $null
            $result.EventDictionary.DateTimeLoggedUTC | Should not be $null
            $result.EventDictionary.Component | Should BeLike "Test-StandardInput"
            $result.EventDictionary.Detail | Should BeLike "TEST"
        }

    }

    # Test Expanded Input (Custom HashTable)
    function Test-ExpandedInput() {
        param($type, $expectedResult)
        #
        # Arrange

        # Get the Asserted Cmdlet
        $assertedCmdlet = $null
        Switch ($type) {
            "information"   { $assertedCmdlet = "Write-Information" }
            "error"         { $assertedCmdlet = "Write-Error" }
            "warning"       { $assertedCmdlet = "Write-Warning" }
            "debug"         { $assertedCmdlet = "Write-Debug" }
            "verbose"       { $assertedCmdlet = "Write-Verbose" }
        }

        # Declare the Expanded Input
        $hashTable = @{
            property = "test"
        }

        # Setup Mocks
        Mock Log-ApplicationInsightsEvent -MockWith {}
        Mock Write-Information {}
        Mock Write-Warning {}
        Mock Write-Error {}
        Mock Write-Verbose {}
        Mock Write-Debug {}

        #
        # Act
        $result = Update-AITraceLog -detail "TEST" -type $type -customHashTable $hashTable -pesterShouldReturnParams

        #
        # Assert

        # Test Standard Output
        it "Should call '$assertedCmdlet' with the expected result" {
            Assert-MockCalled $assertedCmdlet -Times $expectedResult
        }

        # Test Standard Parameters
        it "Should have Standard ParameterSet" {
            $result.InstrumentationKey | Should be $AppInsightsInstrumentationKey
            $result.EventName | Should be $ScriptName
            $result.EventDictionary.ResourceName | Should be $ScriptName
            $result.EventDictionary.EventType | Should be $type
            $result.EventDictionary.DateTimeLogged | Should not be $null
            $result.EventDictionary.DateTimeLoggedUTC | Should not be $null
            $result.EventDictionary.Component | Should BeLike "Test-ExpandedInput"
            $result.EventDictionary.Detail | Should BeLike "TEST"
        }

        # Test Extendend Parameters Applied
        it "Should have the Custom ParameterSet Values (Prefixed with 'custom_')" {
            $result.EventDictionary.custom_property | Should be "test"
        }

    }

    # Test Custom Object Being Passed into it
    function Test-CustomObject() {
        param($type)

        #
        # Arrange

        # Get the Asserted Cmdlet
        $assertedCmdlet = $null
        Switch ($type) {
            "information"   { $assertedCmdlet = "Write-Information" }
            "error"         { $assertedCmdlet = "Write-Error" }
            "warning"       { $assertedCmdlet = "Write-Warning" }
            "debug"         { $assertedCmdlet = "Write-Debug" }
            "verbose"       { $assertedCmdlet = "Write-Verbose" }
        }

        # Setup Mocks
        Mock Log-ApplicationInsightsEvent -MockWith {}
        Mock Write-Information {}
        Mock Write-Warning {}
        Mock Write-Error {}
        Mock Write-Verbose {}
        Mock Write-Debug {}

        # Create a Custom PowerShell Object with Different Types
        $customObj = [PSCustomObject]@{
            StringType = "TEST"
            IntegerType = 1
            LongType = 1
            DateTimeType = Get-Date
            BoolType = $true
            CustomType = [Guid]::NewGuid()
        }

        #
        # Act

        $result = Update-AITraceLog -detail "TEST" -type $type -customObject $customObj -pesterShouldReturnParams

        #
        # Assert

        # Test Standard Output
        it "Should call '$assertedCmdlet' with the expected result" {
            Assert-MockCalled $assertedCmdlet -Times 1
        }

        # Test Standard Parameters
        it "Should have Standard ParameterSet" {
            $result.InstrumentationKey | Should be $AppInsightsInstrumentationKey
            $result.EventName | Should be $ScriptName
            $result.EventDictionary.ResourceName | Should be $ScriptName
            $result.EventDictionary.EventType | Should be $type
            $result.EventDictionary.DateTimeLogged | Should not be $null
            $result.EventDictionary.DateTimeLoggedUTC | Should not be $null
            $result.EventDictionary.Component | Should BeLike "Test-CustomObject"
            $result.EventDictionary.Detail | Should BeLike "TEST"
        }

        # Test for Custom Object being Seralized Correctly
        it "Should have the Custom Object (Prefixed with 'custom_object') set with JSON" {
            $result.EventDictionary.custom_object | Should not be $null
            $result.EventDictionary.custom_object | Should -BeOfType String
            $result.EventDictionary.custom_object.Length | Should not be 0
        }

    }

    function Test-AsyncMethod() {
        param($type)

        #
        # Arrange

        # Get the Asserted Cmdlet
        $assertedCmdlet = $null
        Switch ($type) {
            "information"   { $assertedCmdlet = "Write-Information" }
            "error"         { $assertedCmdlet = "Write-Error" }
            "warning"       { $assertedCmdlet = "Write-Warning" }
            "debug"         { $assertedCmdlet = "Write-Debug" }
            "verbose"       { $assertedCmdlet = "Write-Verbose" }
        }

        # Create Stub mock function
        function Invoke-PSRunspace{}

        # Setup Mocks
        Mock Log-ApplicationInsightsEvent -MockWith {}
        Mock Write-Information {}
        Mock Write-Warning {}
        Mock Write-Error {}
        Mock Write-Verbose {}
        Mock Write-Debug {}
        Mock Invoke-PSRunspace {}

        $PSRunspace = [runspacefactory]::CreateRunspacePool(1,1)
        $PSRunspace.Open()

        #
        # Act
        $result = Update-AITraceLog -detail "TEST" -type $type -pesterShouldReturnParams -AsyncPSRunspaceFactory $PSRunspace

        #
        # Assert

        # Test Standard Output
        it "Should call '$assertedCmdlet' with the expected result" {
            Assert-MockCalled $assertedCmdlet -Times 1
        }

        # Test Standard Parameters
        it "Should have Standard ParameterSet" {
            $result.InstrumentationKey | Should be $AppInsightsInstrumentationKey
            $result.EventName | Should be $ScriptName
            $result.EventDictionary.ResourceName | Should be $ScriptName
            $result.EventDictionary.EventType | Should be $type
            $result.EventDictionary.DateTimeLogged | Should not be $null
            $result.EventDictionary.DateTimeLoggedUTC | Should not be $null
            $result.EventDictionary.Component | Should BeLike "Test-AsyncMethod"
            $result.EventDictionary.Detail | Should BeLike "TEST"
        }

        # Test the Async Method was Called
        it "Should of called Async Job once." {
            Assert-MockCalled Invoke-PSRunspace -Times 1
        }

    }

    #
    # Parameteised Testing
    #

    $types = @('error','information','warning','debug','verbose')

    ForEach ($type in $types) {

        Context "Testing Standard Input with Different Stream Types: $type" {
            Test-StandardInput -type $type -expectedResult 1
        }

        Context "Testing Extended Input (Hashtable) with Different Stream Types: $type" {

            Test-ExpandedInput -type $type -expectedResult 1
        }

        Context "Testing Extended Input (.NET Object) with Different Stream Types: $type" {

            Test-CustomObject -type $type
        }

        Context "Testing (Async) Standard Input (.NET Object) with Different Stream Types: $type" {

            Test-AsyncMethod -type $type
        }

    }

    Context "Testing Error Object Parsing" {

        #
        # Arrange

        # Setup Mocks
        Mock Log-ApplicationInsightsEvent -MockWith {}
        Mock Write-Information {}
        Mock Write-Warning {}
        Mock Write-Error {}
        Mock Write-Verbose {}
        Mock Write-Debug {}

        #
        # Act

        # Create a HashTable Object
        $errorHashTable = @{
            Line = 1
            Char = 1
            Category = "TEST"
            Activity = "TEST"
            Target = "TEST"
            Error = "TEST"
        }

        $result = Update-AITraceLog -type Error -detail "TEST" -errorDetails $errorHashTable -pesterShouldReturnParams

        #
        # Assert

        # Test Standard Output
        it "Should call 'Write-Error' with the expected result" {
            Assert-MockCalled 'Write-Error' -Times 1
        }

        # Test Standard Parameters
        it "Should have Standard ParameterSet" {
            $result.InstrumentationKey | Should be $AppInsightsInstrumentationKey
            $result.EventName | Should be $ScriptName
            $result.EventDictionary.ResourceName | Should be $ScriptName
            $result.EventDictionary.EventType | Should be "ERROR"
            $result.EventDictionary.DateTimeLogged | Should not be $null
            $result.EventDictionary.DateTimeLoggedUTC | Should not be $null
            $result.EventDictionary.Component | Should BeLike "<ScriptBlock>"
        }

        # Detail should of been removed
        it "Detail Property should be been removed from the ParameterSet" {
            $result.EventDictionary.Detail | Should Be $null
        }

        # Test Error Parameters have been added
        it "Test Error Parameters have been added" {
            $result.EventDictionary.Line | Should be 1
            $result.EventDictionary.Char | Should be 1
            $result.EventDictionary.Category | Should be "TEST"
            $result.EventDictionary.Activity | Should be "TEST"
            $result.EventDictionary.Target | Should be "TEST"
            $result.EventDictionary.Error | Should be "TEST"
        }

    }

    Context "Testing Object Length Pruning" {
        #
        # Arrange

        # Setup Mocks
        Mock Log-ApplicationInsightsEvent -MockWith {}
        Mock Write-Information {}
        Mock Write-Warning {}
        Mock Write-Error {}
        Mock Write-Verbose {}
        Mock Write-Debug {}

        #
        # Act

        # Create a HashTable Object which will exceed 4000 charachters in length
        $customObj = [PSObject]@{
            testProperty = "Test"
            testPropertyData = $(0 .. 4000 | ForEach-Object {"a"})
        }

        #
        # Act

        $result = Update-AITraceLog -detail "TEST" -type "information" -customObject $customObj -pesterShouldReturnParams

        #
        # Assert

        # Test Standard Output
        it "Should call 'Write-Information' with the expected result" {
            Assert-MockCalled Write-Information -Times 1
        }

        it "Should called 'Write-Warning' warning the user about pruning" {
            Assert-MockCalled Write-Warning -Times 1
        }

        # Test for Custom Object being Seralized Correctly
        it "Should have the Custom Object (Prefixed with 'custom_object') set with JSON" {
            $result.EventDictionary.custom_object | Should not be $null
            $result.EventDictionary.custom_object | Should -BeOfType String
            $result.EventDictionary.custom_object.Length | Should not be 0
        }

    }

    Context "Testing Property Length Pruning" {
        #
        # Arrange

        # Setup Mocks
        Mock Log-ApplicationInsightsEvent -MockWith {}
        Mock Write-Information {}
        Mock Write-Warning {}
        Mock Write-Error {}
        Mock Write-Verbose {}
        Mock Write-Debug {}

        #
        # Act

        $obj = [PSCustomObject]@{
            Property = "Test"
        }
        # Add 100 Properties to it
        0 .. 10 | ForEach-Object { $obj | Add-Member -MemberType NoteProperty -Name $_ -Value $_ -Force }

        # Create a HashTable Object which will exceed 4000 charachters in length
        $customObj = [PSObject]@{
            testProperty = "Test"
            testPropertyData = $obj
            testPropertyData2 = $obj
            testPropertyData3 = $obj
            testPropertyData4 = $obj
            testPropertyData5 = $obj
            testPropertyData6 = $obj
        }

        #
        # Act

        $result = Update-AITraceLog -detail "TEST" -type "information" -customObject $customObj -pesterShouldReturnParams

        #
        # Assert

        # Test Standard Output
        it "Should call 'Write-Information' with the expected result" {
            Assert-MockCalled Write-Information -Times 1
        }

        it "Should called 'Write-Warning' warning the user about property pruning" {
            Assert-MockCalled Write-Warning -Times 5
        }

        # Test for Custom Object being Seralized Correctly
        it "Should have the Custom Object (Prefixed with 'custom_object') set with JSON" {
            $result.EventDictionary.custom_object | Should not be $null
            $result.EventDictionary.custom_object | Should -BeOfType String
            $result.EventDictionary.custom_object.Length | Should not be 0
        }

        # Test that the Custom Object has been pruned correctly. There should be 2 properties.
        it "Should have the Custom Object (Prefixed with 'custom_object') should have 2 remaining properties" {
            ($result.EventDictionary.custom_object | ConvertFrom-Json | Get-Member -MemberType NoteProperty, Property).Count | Should be 2
        }

    }

}