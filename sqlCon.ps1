# REMOVED CONNECTION CODEBLOCK

$myconnection.Open()
$mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
$mycommand.Connection = $myconnection


$files = Get-ChildItem "S:\freight\unprocessed"

foreach ($f in $files) {

$update = $false

if ([System.IO.File]::Exists("S:\freight\processed\$f")) {

   Remove-Item -Path S:\freight\processed\$f
    $update = $true

}



$path = $f.PSPath

$csv = Import-Csv $f.PSPath -Header header1,header2,header3,header4,header5,header6,header7,header8,header9,header10,header11,header12,header13,header14,header15,header16,header17,header18,header19,header20,header21,header22,header23,header24
$list = New-Object Collections.Generic.List[Object]

$customer = $csv[0].header5
$containerDateUNFORMATTED = $csv[0].header6
$containerDate = $containerDateUNFORMATTED.Split('/')
$formatContainerDate = $containerDate[2] + "-" + $containerDate[0] + "-" + $containerDate[1]
$orderNum = $csv[0].header3
$railyard = $csv[0].header19
$railstreet = $csv[0].header20
$dateProcessed = Get-Date
$containerNum = $csv[1].header8
# Below two lines remove spaces and - and then inserts a space before the check number. 
# SQL schema requires containerNum len to be 12.
$containerNum = $containerNum -replace '(\s|-)',''
$containerNum = $containerNum.Insert(10, ' ')

$containerWeight = $csv[2].header11
if ($containerWeight.Equals(0.0)) {
     $containerWeight = $csv[1].header7
     }


$containerSeal = $csv[1].header10
$containerSize = $csv[1].header11
$contractNum = $csv[1].header12
$carrierName = $csv[1].header14
$bookingNum = $csv[1].header16
$railCutUNFORMATTED = $csv[1].header21
$tempCut = $railCutUNFORMATTED.Split('/')
$etdUNFORMATTED = $csv[1].header20
$tempETD = $etdUNFORMATTED.Split('/')
$etaUNFORMATTED = $csv[1].header23
$tempETA = $etaUNFORMATTED.Split('/')
$year = $csv[0].header10
$vesselName = $csv[1].header15
$vesselNum = $csv[1].header17
$pod = $csv[1].header19
$variety = $csv[2].header4
$description = $csv[2].header5
$ip = $csv[2].header6
$screen = $csv[2].header7
$packageNum = $csv[2].header10
if ($packageNum -eq 673) {
     $packageNum = 672
     }
if ($packageNum -eq 21) {
     $packageNum = 20
     }
$packageType = $csv[2].header9
$package = $csv[2].header8
$railCut = $tempCut[2] + "-" + $tempCut[0] + "-" + $tempCut[1]
$etd = $tempETD[2] + "-" + $tempETD[0] + "-" + $tempETD[1]
$eta = $tempETA[2] + "-" + $tempETA[0] + "-" + $tempETA[1]


try {
# SENDS SQL QUERY TO RETRIEVE CUSTOMERID PRIMARY KEY
    #$mycommand.CommandText = "SELECT customerID FROM customer WHERE customerName = '$customer'"
    #$myreader = $mycommand.ExecuteReader()
    #$myreader.Read()
    #$customerIDNUM = $myreader.GetValue(0)
    #$myreader.Close()
    $mycommand.CommandText = "SELECT customerID FROM customer WHERE customerName = '$customer'"
    $myreader = $mycommand.ExecuteReader()
    
    if($myreader.Read()) {
        $customerIDNUM = $myreader.GetValue(0)

    }

    else {
        $myreader.close()
        $mycommand.CommandText = "INSERT INTO customer (customerName) VALUES ('$customer')"
        $myreader = $mycommand.ExecuteReader()
        $myreader.Close()
        $mycommand.CommandText = "SELECT customerID FROM customer WHERE customerName = '$customer'"
        $myreader = $mycommand.ExecuteReader()
        $customerread = $myreader.Read()
        $customerIDNUM = $myreader.GetValue(0)
        
    }

    $myreader.Close()
# SENDS SQL QUERY TO RETRIEVE CARRIERID PRIMARY KEY    
    #$mycommand.CommandText = "SELECT carrierID from carrier WHERE carrierName = '$carrierName'"
    #$myreader = $mycommand.ExecuteReader()
    #$myreader.Read()
    #$carrierIDNUM = $myreader.GetValue(0)
    #$myreader.Close()

    $mycommand.CommandText = "SELECT carrierID from carrier WHERE carrierName = '$carrierName'"
    $myreader = $mycommand.ExecuteReader()
    
    if($myreader.Read()) {
        $carrierIDNUM = $myreader.GetValue(0)

    }

    else {
        $myreader.close()
        $mycommand.CommandText = "INSERT INTO carrier (carrierName) VALUES ('$carrierName')"
        $myreader = $mycommand.ExecuteReader()
        $myreader.Close()
        $mycommand.CommandText = "SELECT carrierID from carrier WHERE carrierName = '$carrierName'"
        $myreader = $mycommand.ExecuteReader()
        $carrierread = $myreader.Read()
        $carrierIDNUM = $myreader.GetValue(0)

    }

    $myreader.Close()

# CHECKS IF CONTRACT TABLE CONTAINS CONTRACTNUM IF NOT ADD IT TO TABLE,
# OTHERWISE RETRIEVE CONTRACTID PRIMARY KEY
    $mycommand.CommandText = "SELECT contractID from contract WHERE contractNumber = '$contractNum'"
    $myreader = $mycommand.ExecuteReader()
    
    if($myreader.Read()) {
        $contractIDNUM = $myreader.GetValue(0)

    }
    else {
        $myreader.close()
        $mycommand.CommandText = "INSERT INTO contract (contractNumber) VALUES ('$contractNum')"
        $myreader = $mycommand.ExecuteReader()
        $myreader.Close()
        $mycommand.CommandText = "SELECT contractID from contract WHERE contractNumber = '$contractNum'"
        $myreader = $mycommand.ExecuteReader()
        $contractread = $myreader.Read()
        $contractIDNUM = $myreader.GetValue(0)
        
    }

    $myreader.Close()

#Now that we have all necessary FK's we can add to our booking table
    $mycommand.CommandText = "SELECT bookingID from booking WHERE bookingNum = '$bookingNum'"
    $myreader = $mycommand.ExecuteReader()
    
    if($myreader.Read()) {
        $bookingIDNUM = $myreader.GetValue(0)

    }
    else {
        $myreader.close()
        if($variety.Equals("DRIEDDISTILLERSGRAIN")) {
            New-Item -Path "S:\DDG Shipments" -Name "$bookingNum" -ItemType "directory"
             New-Item -Path "S:\DDG Shipments" -Name "$bookingNum\BOL" -ItemType "directory"
              New-Item -Path "S:\DDG Shipments" -Name "$bookingNum\PACKING" -ItemType "directory"
            
        }
        else {

            New-Item -Path "S:\Bean Shipments" -Name "$bookingNum" -ItemType "directory"
            New-Item -Path "S:\Bean Shipments" -Name "$bookingNum\BOL" -ItemType "directory"
            New-Item -Path "S:\Bean Shipments" -Name "$bookingNum\PACKING" -ItemType "directory"

        }

        $mycommand.CommandText = "INSERT INTO booking (bookingNum, bookingLot, bookingVessel, bookingVesselNum, 
        bookingCut, bookingETD, bookingETA, bookingPOD, bookingCarrierID, bookingContractID, bookingCustomerID) 
        VALUES ('$bookingNum', '$bookingNum', '$vesselName', '$vesselNum', '$railCut', '$etd', '$eta', '$pod', '$carrierIDNUM', 
        '$contractIDNUM', '$customerIDNUM')"
        $myreader = $mycommand.ExecuteReader()
        $myreader.Close()
        $mycommand.CommandText = "SELECT bookingID from booking WHERE bookingNum = '$bookingNum'"
        
        $myreader = $mycommand.ExecuteReader()
        $bookingread = $myreader.Read()
        $bookingIDNUM = $myreader.GetValue(0)
        
    }

    $myreader.Close()

#And finally now that we have our bookingIDNUM we can add to our container table
    


    $mycommand.CommandText = "SELECT containerID from container WHERE containerNum = '$containerNum'"
    $myreader = $mycommand.ExecuteReader()

    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    if($myreader.Read()) {
    $cID = $myreader.GetValue(0)
    $myreader.close()
        $mycommand.CommandText = "Update container set containerSize = '$containerSize', containerWeight = $containerWeight , 
    containerProduct = '$variety' , containerPackage = '$package', containerSeal = '$containerSeal', containerBookingID = '$bookingIDNUM' , containerOrderNumber = '$orderNum' , containerDate = '$formatContainerDate' , containerDescription = '$description' , containerIP = '$ip' , containerScreen = '$screen' , containerPackageType = '$packageType' , containerPackageNum = '$packageNum' , containerRailyard = '$railyard' , containerStreet = '$railStreet', containerYear = '$year' where containerID = $cID "
    
    $myreader= $mycommand.ExecuteReader()
        
        

    }
    elseif($update) {
    $mycommand.CommandText = "SELECT containerID from container WHERE containerSeal = '$containerSeal'"
    $myreader = $mycommand.ExecuteReader()

    if($myreader.Read()) {
        $tempSeal = $myreader.GetValue(0)
        $myreader.close()

        $mycommand.CommandText = "Update container set containerNum = '$containerNum', containerSize = '$containerSize', containerWeight = $containerWeight , 
    containerProduct = '$variety' , containerPackage = '$package', containerBookingID = '$bookingIDNUM' , containerOrderNumber = '$orderNum' , containerDate = '$formatContainerDate' , containerDescription = '$description' , containerIP = '$ip' , containerScreen = '$screen' , containerPackageType = '$packageType' , containerPackageNum = '$packageNum' , containerRailyard = '$railyard' , containerStreet = '$railStreet', containerYear = '$year' where containerID = $cID "
    $myreader= $mycommand.ExecuteReader()



    }

    }
    else {
        $myreader.close()
        

        $mycommand.CommandText = "INSERT INTO container (containerNum, containerSize, containerWeight, 
    containerProduct, containerPackage, containerSeal, containerBookingID, containerTimeLoaded, containerOrderNumber, containerDate, containerDescription, containerIP, containerScreen, containerPackageType, containerPackageNum, containerRailyard, containerStreet, containerYear)
    VALUES ('$containerNum', '$containerSize', '$containerWeight', '$variety', '$package', '$containerSeal', 
    '$bookingIDNUM', '$date', '$orderNum', '$formatContainerDate', '$description', '$ip', '$screen','$packageType', '$packageNum', '$railyard', '$railstreet', '$year')"
    $myreader = $mycommand.ExecuteReader()
        
    }

    
    $myreader.Close()

    Move-Item -Path $f.PSPath -Destination S:\freight\processed
    
    
}

catch {

$Error

}

finally {
$myreader.Close()
$myconnection.close()
exit

}
 

}
