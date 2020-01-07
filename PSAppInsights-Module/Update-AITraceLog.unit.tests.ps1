Describe "Update-AITraceLog Unit Tests" {

    BeforeAll {

        # Dot Source the Function into Memory
        . .\Update-AITraceLog.ps1

        # Mock all Screen Printouts
        Mock Write-Verbose {return}
        Mock Write-Error {return}
        Mock Write-Information {return}
        Mock Write-Warning {return}
        Mock Write-Debug {return}

    }

    AfterEach {

        # Cleanup InstrumentationKey (if Declared)
        if ($Global:AISingleton) {
            $Global:AISingleton = $null
        }
    }

    Context "Cmdlet is Missing ResourceName Parameter" {

        # Arrange

        # Act

        # Assert
        it "Should Throw: 'Missing -ResourceName Parameter or Missing `$RunbookName variable.'" {
            { Update-AITraceLog -Detail "TEST" } | Should -Throw "Missing -ResourceName Parameter or Missing `$RunbookName variable."
        }

    }

    Context "Cmdlet 'New-AIClient' has not been invoked. Has '-InstrumentationKey' Parameter Defined" {

        # Arrange
        Mock New-AIClient -MockWith { return }
        Mock Send-AITrace  -MockWith { return }
        Mock Send-AIException  -MockWith { return }

        # Act
        $null = Update-AITraceLog -Detail "TEST" -InstrumentationKey "TEST" -ResourceName "TEST"

        # Assert
        it "Should call 'New-AIClient' with the expected result" {
            Assert-MockCalled -CommandName New-AIClient -Exactly 1
        }
    }

    $LogStreamTypes = @("Information", "Warning", "Error", "Verbose", "Debug")

    ForEach($LogStreamType in $LogStreamTypes) {

        Context "Cmdlet Standard Execution with LogStreamType: $LogStreamType"  {

            # Arrange
            Mock New-AIClient -MockWith { return }
            Mock Send-AITrace  -MockWith { return }
            Mock Send-AIException  -MockWith { return }        
            # Mock Object
            $Global:AISingleton = [PSCustomObject]@{
                InstrumentationKey = "TEST"
            }

            # Act
            $result = Update-AITraceLog -Detail "TEST" -InstrumentationKey "TEST" -ResourceName "TEST" -pesterShouldReturnParams -type $LogStreamType

            # Assert
            it "$LogStreamType : Shouldn't have called 'New-AIClient'" {
                Assert-MockCalled -CommandName New-AIClient -Exactly 0
            }
            it "$LogStreamType : Shouldn't have called 'Send-AIException'" {
                Assert-MockCalled -CommandName Send-AIException -Exactly 0
            }        
            it "$LogStreamType : Should call 'Send-AITrace' with the expected result" {
                Assert-MockCalled -CommandName Send-AITrace -Exactly 1
            }
            it "$LogStreamType : Should call 'Write-$LogStreamType' with the expected result" {

                switch ($LogStreamType) {
                    'Information'   { Assert-MockCalled -CommandName "Write-Information"    -Exactly 1 }
                    'Warning'       { Assert-MockCalled -CommandName "Write-Warning"        -Exactly 1 }
                    'Error'         { Assert-MockCalled -CommandName "Write-Error"          -Exactly 1 }
                    'Verbose'       { Assert-MockCalled -CommandName "Write-Verbose"        -Exactly 1 }
                    'Debug'         { Assert-MockCalled -CommandName "Write-Debug"          -Exactly 1 }
                    default         { throw "LogStreamType is not known"                               }
                }

            }
            it "$LogStreamType : Should of returned a param Object" {
                $result.Message | Should Not BeNullOrEmpty
                $result.Properties | Should Not  BeNullOrEmpty
                $result.SeverityLevel | Should Not BeNullOrEmpty
                $result.FullStack | Should Not BeNullOrEmpty
            }
        }
    }

    Context "Cmdlet Standard Execution with Exception" {

        # Arrange
        Mock New-AIClient -MockWith { return }
        Mock Send-AITrace  -MockWith { return }
        Mock Send-AIException  -MockWith { return }        
        # Mock Object
        $Global:AISingleton = [PSCustomObject]@{
            InstrumentationKey = "TEST"
        }

        # Act

        $params = @{
            Detail = "TEST"
            InstrumentationKey = "TEST"
            ResourceName = "TEST"
            pesterShouldReturnParams = $true
            type = "Error"
            errorDetails = @{
                TestProperty1 = "TEST"
                TestProperty2 = "TEST"
            }
        }

        $result = Update-AITraceLog @params

        # Assert
        it "Shouldn't have called 'New-AIClient'" {
            Assert-MockCalled -CommandName New-AIClient -Exactly 0
        }
        it "Should call 'Send-AIException'" {
            Assert-MockCalled -CommandName Send-AIException -Exactly 1
        }        
        it "Shouldn't have called 'Send-AITrace' with the expected result" {
            Assert-MockCalled -CommandName Send-AITrace -Exactly 0
        }
        it "Should of returned a param Object" {
            $result.ErrorInfo | Should Not BeNullOrEmpty
            $result.Properties | Should Not  BeNullOrEmpty
            $result.Properties.ResourceName | Should Not BeNullOrEmpty
            $result.Properties.DateTime | Should Not BeNullOrEmpty
            $result.Properties.Component | Should Not BeNullOrEmpty
            $result.Properties.TestProperty1 | Should Not BeNullOrEmpty
            $result.Properties.TestProperty2 | Should Not BeNullOrEmpty
        }

    }

}