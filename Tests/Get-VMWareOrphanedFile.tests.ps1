﻿# ----- Get the module name
if ( -Not $PSScriptRoot ) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

Write-Output "PSScriptRoot = $PSScriptRoot"

$ModulePath = $PSScriptRoot.substring(0,$PSScriptRoot.LastIndexOf('\'))

Write-output "ModulePath = $ModulePath"

$Global:ModuleName = $ModulePath | Split-Path -Leaf

Write-Output "ModuleName = $ModuleName"

# ----- This line is required if the test is invoke by itself.  
if ( -Not (Get-Module -Name $ModuleName) ) { Import-Module "$ModulePath\$ModuleName.PSD1" -Force -ErrorAction Stop }

#-------------------------------------------------------------------------------------

Describe "$ModuleName : Get-VMWareOrphanedFile" -Tags DataStore {
       
            Mock -Command New-Object -ParameterFilter { $TypeName -eq 'VMware.Vim.FileQueryFlags' } -MockWith {
                $Obj = @{
                    FileOwner = $true
                    FileSize = $true
                    FileType = $true
                    Modification = $true 
                }
    
                Return $Obj
            } -Verifiable

            Mock -Command New-Object -ParameterFilter { $TypeName -eq 'VMware.Vim.FloppyImageFileQuery' } -MockWith { Return $Null }

            Mock -Command New-Object -ParameterFilter { $TypeName -eq 'VMware.Vim.FolderFileQuery' } -MockWith {}

            Mock -Command New-Object -ParameterFilter { $TypeName -eq 'VMware.Vim.IsoImageFileQuery' } -MockWith {}

            Mock -Command New-Object -ParameterFilter { $TypeName -eq 'VMware.Vim.VmConfigFileQuery' } -MockWith {
                Return (@{
                    Details = $Null
                })
            }

            Mock -Command New-Object -ParameterFilter { $TypeName -eq 'VMware.Vim.VmConfigFileQueryFlags' } -MockWith {
                Return (@{
                    ConfigVersion = $true
                }) 
            }

            Mock -Command New-Object -ParameterFilter { $TypeName -eq 'VMware.Vim.TemplateConfigFileQuery' } -MockWith {
                Return (@{
                    Details = $Null
                })
            }

            Mock -Command New-Object -ParameterFilter { $TypeName -eq 'VMware.Vim.VmDiskFileQuery' } -MockWith {
                Return (@{
                    Details = $Null
                })
            }

            Mock -Command New-Object -ParameterFilter { $TypeName -eq 'VMware.Vim.VmDiskFileQueryFlags' } -MockWith {  
                Return (@{
                    CapacityKB = $true
                    DiskExtents = $true
                    DiskType = $true
                    HardwareVersion = $true
                    Thin = $true
                }) 
            }

            Mock -Command New-Object -ParameterFilter { $TypeName-eq 'VMware.Vim.VmLogFileQuery' } -MockWith {}

            Mock -Command New-Object -ParameterFilter { $TypeName-eq 'VMware.Vim.VmNvramFileQuery' } -MockWith {}

            Mock -Command New-Object -ParameterFilter { $TypeName-eq 'VMware.Vim.VmSnapshotFileQuery' } -MockWith {}

            Mock -Command New-Object -ParameterFilter { $TypeName-eq 'VMware.Vim.HostDatastoreBrowserSearchSpec' } -MockWith {
                Return (@{
                    details = $Null
                    Query = $Null
                    sortFoldersFirst = $Null
                }) 
            }

            Mock -Command Get-DataStore -MockWith {
                $MultipleHostAccessObj = (@{
                    MultipleHostAccess = $True
                })

                $BrowserObj = (@{
                    Type = 'HostDatastoreBrowser'
                    Value = 'datastoreBrowser-datastore-9999'
                })

                $ExtensionDataObj = (@{
                    Browser = $BrowserObj
                    Summary = $MultipleHostAccessObj
                })

                Return (@{
                    Type = "VMFS"
                    ExtensionData = $ExtensionDataObj
                    ID = $Null
                    Accessible = $True
                    Name = "Vol1"
                }) 
            }

            Mock -Command Get-View -ParameterFilter { $ID } -MockWith {

                $obj = (@{}) 

                $Obj | Add-Member -MemberType ScriptMethod -Name SearchDatastoreSubFolders -Value {
                    Param ( $rootPath, $searchSpec )

                    $FileObj = (@{
                        Path = 'TestDrive:\temp'
                    })

                    Return (@{
                        File = $FileObj
                        FolderPath = 'TestDrive:\temp'
                    })
                }

                Return $Obj
            }

             Mock -Command Get-VM -ParameterFilter { $DataStore } -MockWith {

                $NameObj = (@{
                    Name = 'TestVM'
                })
        
                $FileObj = (@{
                    File = $NameObj
                })
        
                $LayoutObj = (@{
                    Layout = $FileObj
                })
  
                Return (@{
                    ExtensionData = $LayoutObj
                }) 
            }

            Mock -CommandName Get-Template -MockWith {

                $NameObj = (@{
                    Name = $Null
                })
        
                $FileObj = (@{
                    File = $NameObj
                })
        
                $LayoutObj = (@{
                    Layout = $FileObj
                })

                Return (@{
                    ExtensionData = $LayoutObj
                    DatastoreIdList = $Null
                }) 
            }

        Context Execution {

            # ----- Currently having issues mocking Get-Vm.  This throws thefollowing error.
            # ----- the expression not to throw an exception. Message was {Cannot process argument transformation on parameter 'Datastore'. Cannot convert the "System.Collections.Hashtable" value of type "System.Collections.Hashtable" to type "VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.StorageResource[]"

            
            It "Cannot mock PowerCLI Cmdlets ( https://github.com/pester/Pester/issues/803 )" {
                $True | Should be $True
            } -pending


    #        It "Should accept pipeline input of type String and Convert it to a Datastore Object" {
    #            $DS = 'Vol1'

    #            { $DS | Get-VMWareOrphanedFiles -verbose } | Should not Throw

    #            Assert-VerifiableMocks
    #        } -Pending

      #      It "Should accept Pipeline Input of type DataStore (VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.VmfsDatastoreImpl)" {
      #          $DS = Mock-NewObject -Type VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.VmfsDatastoreImpl {}
      #
      #          { $DS | Get-VMWareOrphanedFiles } | Should not Throw
      #      } -pending
      #
      #  
      #      It "Should accept pipeline input of an array of Strings and convert it to a DataStore object" {
      #          $DS = 'Vol1','Vol2'
      #
      #          { $DS | Get-VMWareOrphanedFiles } | Should not Throw
      #      } -pending
      #
      #      It "Should write a warning if the datastore is not of type VMFS" {
      #
      #          Mock -Command Get-DataStore -MockWith {
      #              $BrowserObj = New-Object -TypeName PSObject (@{
      #                  Browser = $Null
      #              })
      #
      #              New-Object -TypeName PSObject -Property (@{
      #                  Type = 'nonVMFS'
      #                  ExtensionData = $BrowserObj
      #                  ID = $Null
      #                  Name = 'Vol1'
      #              }) 
      #          }
      #
      #          $DS = 'Vol1'
      #
      #          $DS | Get-VMWareOrphanedFiles 3>&1 | Should Match "Get-VMWareOrphanedFiles : Skipping Vol1 as it is not a VMFS datastore."
      #
      #      } -Pending

        }

      #  Context output {
      #
      #      it "Should return a Custom Powershell Object" {
      #          $DS = 'Vol1'
      #
      #          $DS | Get-VMWareOrphanedFiles | Should beoftype PSObject
      #      } -pending
      #
      #  }

    }
