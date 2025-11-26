Connect-MgGraph

# Get all CA policies that target Microsoft Admin Portals
Get-MgIdentityConditionalAccessPolicy -All |
    Where-Object {
        $_.Conditions.Applications.IncludeApplications -contains 'MicrosoftAdminPortals'
    } |
    Select-Object Id, DisplayName, State,
        @{Name='IncludeApplications';Expression={$_.Conditions.Applications.IncludeApplications}}
