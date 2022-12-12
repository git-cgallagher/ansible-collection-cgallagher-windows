#!powershell

# Copyright: (c) 2022 VMware, Inc. All Rights Reserved.
# SPDX-License-Identifier: Internal

#AnsibleRequires -CSharpUtil Ansible.Basic
$spec = @{
    options = @{
        state = @{ type = "str"; default = 'present'; choices = @('present','absent','rename') }
        name = @{ type = "str"; required = $true }
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
}

# see if new_name exists
If ($current_sites.name -contains $new_name) {
    $new_site_exists = $true
}

# when state eq present
If ($state -eq "present") {
    If (-not $site_exists) {
        Try {
            New-ADReplicationSite -Identity $name
            $module.Result.changed = $true
        } Catch {
            $module.FailJson("Failed to add site: $($_.Exception.Message)", $_)
        }
    }
}


# when state eq absent
If ($state -eq "absent") {
    If ($site_exists) {
        Try {
            $links = Get-ADReplicationSiteLink -Filter "SitesIncluded -eq $name"
            Foreach($link in $links) {
                Try {
                    Remove-ADReplicationSiteLink -Identity $link
                    $module.Result.changed = $true
                } Catch {
                    $module.FailJson("Failed to remove all site links before removing site: $($_.Exception.Message)", $_)
                }
            }
            Remove-ADReplicationSite -Identity $name
            $module.Result.changed = $true
        } Catch {
            $module.FailJson("Failed to remove site: $($_.Exception.Message)", $_)
        }
    }
}


# when state eq rename
If ($state -eq "rename") {
    If (($site_exists) -and (-not $new_site_exists)) {
        Try {
            Get-AdReplicationSite -Identity $name | Rename-ADObject $new_name
            $module.Result.changed = $true
        } Catch {
            $module.FailJson("Failed to rename site: $($_.Exception.Message)", $_)
        }
    }
}


$module.ExitJson()
