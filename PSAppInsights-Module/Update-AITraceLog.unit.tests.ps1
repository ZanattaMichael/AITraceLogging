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

    Context "Missing Resource Name" {

        # Arrange
        Mock throw { return "ERROR" }

        # Act

        # Assert
        it "Should Throw an Error" {
            { Update-AITraceLog -Detail "TEST" } | Should -Throw "ERROR"
        }

    }

    Context "Missing Cmdlet: New-AIClient. Has -InstrumentationKey" {

        # Arrange
        Mock -ModuleName PSAppInsights New-AIClient { return }
        Mock -ModuleName PSAppInsights Send-AITrace { return }
        Mock -ModuleName PSAppInsights Send-AIException { return }
        # Act
        

        # Assert


    }


    Context "Standard Execution: "  {

        # Arrange
        $Global:AISingleton.InstrumentationKey = "TEST"

    }





}