#!powershell

# Copyright: (c) 2022 VMware, Inc. All Rights Reserved.
# SPDX-License-Identifier: Internal

#AnsibleRequires -CSharpUtil Ansible.Basic
#Requires -Module ActiveDirectory

$spec = @{
    options             = @{
        state    = @{ type = "str"; default = 'present'; choices = @('present', 'absent', 'rename') }
        name     = @{ type = "str"; required = $true }
        new_name = @{ type = "str"; required = $false }
    }
    supports_check_mode = $false
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$state = $module.Params.state
$name = $module.Params.name
$new_name = $module.Params.new_name

# try to load ActiveDirectory Module
Try { Import-Module ActiveDirectory }
Catch { $module.FailJson("Failed to load ActiveDirectory module: $($_.Exception.Message)", $_) }

# see if site exists
Try { $current_sites = Get-ADReplicationSite -Filter * }
Catch { $module.FailJson("Failed to determine current sites: $($_.Exception.Message)", $_) }

If ($current_sites.name -contains $name) {
    $site_exists = $true
    If ($site_exists) {
        $dc_in_site = Get-ADDomainController -Discover -SiteName $name -ErrorAction SilentlyContinue
    }
}

# see if new_name exists
If ($current_sites.name -contains $new_name) {
    $new_site_exists = $true
}

# when state eq present
If ($state -eq "present") {
    If (-not $site_exists) {
        Try {
            New-ADReplicationSite -Name $name
            $module.Result.changed = $true
        }
        Catch {
            $module.FailJson("Failed to add site: $($_.Exception.Message)", $_)
        }
    }
}


# when state eq absent
If ($state -eq "absent") {
    If ($site_exists) {
        If ($dc_in_site) {
            $module.FailJson("Failed before removing site: The site cannot be deleted because the following server objects are present in the site: $dc_in_site")
        }
        If (-not $dc_in_site) {
            Try {
                $links = Get-ADReplicationSiteLink -Filter "SitesIncluded -eq '$name'"
                If ($links) {
                    Foreach ($link in $links) {
                        Try {
                            Remove-ADReplicationSiteLink -Identity $link -Confirm:$False
                            $module.Result.changed = $true
                        }
                        Catch {
                            $module.FailJson("Failed to remove all site links before removing site: $($_.Exception.Message)", $_)
                        }
                    }
                }
                Remove-ADReplicationSite -Identity $name -Confirm:$False
                $module.Result.changed = $true
            }
            Catch {
                $module.FailJson("Failed to remove site: $($_.Exception.Message)", $_)
            }
        }
    }
}


# when state eq rename
If ($state -eq "rename") {
    If (($site_exists) -and (-not $new_site_exists)) {
        Try {
            Get-AdReplicationSite -Identity $name | Rename-ADObject -NewName $new_name
            $module.Result.changed = $true
        }
        Catch {
            $module.FailJson("Failed to rename site: $($_.Exception.Message)", $_)
        }
    }
}


$module.ExitJson()
