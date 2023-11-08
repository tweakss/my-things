<#
    Overview: In general this gets all the laptops and computers from AD, then
    gives you a count of the laptops/computers from each department and then a
    total sum of laptops/computers. Finally it exports only the department and hostname of
    each computer as a .csv file. Each entry of the .csv file is of "dept,HOSTNAME".
#>

# Queries AD and gets each department from 'Departments' OU then stores it in an array.
$departments = @(Get-ADOrganizationalUnit -Filter * -SearchBase "OU=Departments,DC=ersteny,DC=com" -SearchScope OneLevel | Select-Object -Property Name,DistinguishedName)

# Assigns all the depts from Accounting to Risk, leaving out 'Visitors' dept.
$departments = $departments[0..($departments.length - 2)]

$numOfDepts = ($departments | Measure-Object).Count
Write-Host "numOfDepts: ${numOfDepts}" -ForegroundColor Cyan

# Loops through $departments and uses the 'DistinguishedName' property of each dept object 
# to query AD for the respective computer objects in each department's laptop OU.
$computers # Used to store the computer objects from Get-ADComputer.
for($i = 0; $i -lt $departments.length; $i++) {
    Write-Host "[${i}]" -NoNewline -ForegroundColor Cyan
    Write-Host "Dept: $($departments[${i}].Name) | DistinguishedName: $($departments[${i}].DistinguishedName)" -ForegroundColor Green

    # Queries and gets the computer objects by using the 'DistinuguishedName' property.
    # Then it creates a custom label/column called 'Dept' with each value (expression) as
    # the name of each department. The other column is 'Name' which is the hostname.
    $deptLaptops = Get-ADComputer -Filter * -SearchBase "OU=Laptops,$($departments[${i}].DistinguishedName)" -Properties CanonicalName |
        Select-Object -Property @{label='Dept';expression={ $splitted = $_.CanonicalName.split("/"); $indexOfDept = $splitted.IndexOf("Departments") + 1; return $splitted[$indexOfDept];} },Name
    
    # This is only for Maria's desktop computer since it is not in the laptop OU. It
    # queries and gets the computer object in the computer OU then stores the computer
    # object and counts it.
    if($departments[${i}].Name -eq "General_Services") {
        $deptComputers = Get-ADComputer -Filter * -SearchBase "OU=Computers,$($departments[${i}].DistinguishedName)" -Properties CanonicalName | 
            Select-Object -Property @{label='Dept';expression={ $splitted = $_.CanonicalName.split("/"); $indexOfDept = $splitted.IndexOf("Departments") + 1; return $splitted[$indexOfDept];} },Name
        
        $computers += $deptComputers
        $deptComputersCount = ($deptComputers | Measure-Object).Count
        Write-Host "deptComputers count:", $deptComputersCount -ForegroundColor Cyan
    }

    # Stores/appends the computer objects and counts it
    $computers += $deptLaptops
    $deptLaptopsCount = ($deptLaptops | Measure-Object).Count
    Write-Host "deptLaptops count:", $deptLaptopsCount -ForegroundColor Cyan
    Write-Host "___" -ForegroundColor DarkMagenta
}

$totalNumOfComputers = $computers.Length
Write-Host "`ntotalNumOfComputers: ${totalNumOfComputers}" -ForegroundColor Green

# Exports the computer objects into a .csv file
$computers | Export-Csv -Path "\\gcny\nybroot\Information_Tech\belee\AD cleanup\AD_Computers.csv" -NoTypeInformation
