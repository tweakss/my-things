<#
    Prerequisites:
    1. Make a .csv file for $hostnamesFromInven with just two columns: 'Department' and
    'Hostname'. Copy and paste the entire 'Department' column and 'Hostname' column from the
    inventory spreadsheet and include a first row (Department and Hostname) in the new
    .csv file.
    2. Put the inventory .csv file and AD .csv file in the same location/folder.
    3. Make sure all the hostnames in each .csv file are in uppercase.

    Overview: This script requires the use of two .csv files since it checks if each 
    delimited value in one of the .csv file is contained in the other .csv file and vice 
    versa. 

    For keeping track of the computers, AD is considered as the source/origin and the 
    inventory as the non-source/origin, meaning AD should always contain the valid amount 
    of computers and valid listed computers. 
    
    But for everything to be valid, AD and the inventory needs to match up, meaning both 
    AD and the inventory needs to contain the same exact amount of computers and each 
    respective computer is listed on both sides. So to ensure this the AD .csv is 
    checked against the Inventory .csv and the Inventory .csv is checked against the AD .csv.
    
#>

# Reads and stores the data of the .csv files
$hostnamesFromInven = Get-Content -Path "\\gcny\nybroot\Information_Tech\belee\AD cleanup\hostnamesFromInventory test.csv"
$hostnamesFromAD = Get-Content -Path "\\gcny\nybroot\Information_Tech\belee\AD cleanup\AD_Computers test.csv"

# Edits the AD .csv values so that the values are of the same format as the inventory's.
$hostnamesFromAD_formatted = @(0..($hostnamesFromAD.Length - 1))
for($i = 0; $i -lt $hostnamesFromAD.Length; $i++) {
    $lineFormatted = $hostnamesFromAD[$i].replace('"', '')
    $hostnamesFromAD_formatted.SetValue($lineFormatted, $i)
}

Write-Host "AD contains {computer} from inven..." -ForegroundColor Magenta

$AD_ContainsCount = 0
$AD_NotContainsCount = 0

# This is a List object which will contain 'string' objects. I used a List object instead
# of an array for performance or just for best practice.
$AD_notContains = New-Object -TypeName System.Collections.Generic.List[string]

# Goes through the Inventory .csv line by line and checks if the AD .csv contains each line
# and counts it. It also stores the line if AD doesn't contain that line.
for($i = 1; $i -lt $hostnamesFromInven.Length; $i++) {
    $line = $hostnamesFromInven[$i]
    
    if(!$hostnamesFromAD_formatted.Contains($line)) {
        Write-Host "AD does not contain $line from inven" -ForegroundColor Red
        $AD_NotContainsCount += 1
        $AD_notContains.Add($line)
    } else {
        Write-Host "AD contains $line, from inven" -ForegroundColor Green
        $AD_ContainsCount += 1
    }
}
Write-Host "AD contains ${AD_ContainsCount} computers from inven" -ForegroundColor Magenta
Write-Host "AD does not contain ${AD_NotContainsCount} computers from inven" -ForegroundColor Magenta
Write-Host "__END" -ForegroundColor Magenta

Write-Host "Inven contains {computer} from AD..." -ForegroundColor Magenta
$inven_ContainsCount = 0
$inven_NotContainsCount = 0
$inven_notContains = New-Object -TypeName System.Collections.Generic.List[string]

# Goes through the AD .csv line by line and checks if the Inventory .csv contains each line
# and counts it. It also stores the line if Inventory doesn't contain that line.
for($i = 1; $i -lt $hostnamesFromAD_formatted.Length; $i++) {
    $line = $hostnamesFromAD_formatted[$i]
    
    if(!$hostnamesFromInven.Contains($line)) {
        Write-Host "Inven does not contain $line from AD" -ForegroundColor Red
        $inven_NotContainsCount += 1
        $inven_notContains.Add($line)
    } else {
        Write-Host "Inven contains, $line from AD" -ForegroundColor Green
        $inven_ContainsCount += 1
    }
}
Write-Host "Inven contains ${inven_ContainsCount} computers from AD" -ForegroundColor Magenta
Write-Host "Inven does not contain ${inven_NotContainsCount} computers from AD" -ForegroundColor Magenta
Write-Host "__END" -ForegroundColor Magenta

# Outputs a summary of the checks
Write-Host "`n__Summary:" -ForegroundColor Yellow
Write-Host "Inventory has $($hostnamesFromInven.length - 1) total computers...
- AD Contains $AD_ContainsCount computers from inven
- AD does not contain $AD_NotContainsCount computers from inven" -ForegroundColor Yellow
foreach($computer in $AD_notContains) {
    Write-Host "    $computer" -ForegroundColor Red
}

Write-Host "AD has $($hostnamesFromAD.Length - 1) total computers...
- Inven contains $inven_ContainsCount computers from AD
- Inven does not contain $inven_NotContainsCount computers from AD" -ForegroundColor Yellow
foreach($computer in $inven_notContains) {
    Write-Host "    $computer" -ForegroundColor Red
}

# If the count
if( ($AD_ContainsCount -eq $hostnamesFromInven.Length - 1) -and ($AD_ContainsCount -eq $hostnamesFromAD.Length - 1) ) {
    Write-Host "`nInventory and AD matches each other" -ForegroundColor Green
}