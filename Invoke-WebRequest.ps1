# Script to use Invoke-WebRequest to download a webpage and the ParsedHTML library to parse the tags
# KOAES 17 November 2018
# Parse questions for technical certifications

add-type @”
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
public bool CheckValidationResult(
ServicePoint srvPoint, X509Certificate certificate,
WebRequest request, int certificateProblem) {
return true;
}
}
“@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Array to hold the final parsed items


$url = "https://www.briefmenow.org/ec-council/what-type-of-alert-is-the-ids-giving-2/"
#$url = "https://www.briefmenow.org/cisco/which-of-the-following-is-the-only-device-that-requires-2/"

for($i=0; $i -lt 500; $i++){
$final = ""
$explaination = ""
$array = New-Object System.Collections.Generic.List[System.Object]
# Invoke-WebRequest to get html
write-host "==== Attempt " $i " for " $url
$response = Invoke-WebRequest -Uri $url

# Parse the Div tag named "entry-content"; this contains the question and answers
$parsedResponse = ($response.ParsedHtml.getElementsByTagName("Div") | Where{ $_.className -eq "entry-content"})
$nextlink = ($response.ParsedHtml.getElementsByTagName("Div") | Where{ $_.className -eq "nav-next"}).innerHTML
$link = $nextlink.split('"')
$url = $link[3]

#Debug Line to display the HTML of the page
#write-host ($response.ParsedHtml.getElementsByTagName("Div") | Where{ $_.className -eq "entry-content"}).innerHTML


# Parse for the P tags
$parsedResponse.getElementsByTagName("P") | ForEach-Object {$array.Add($_.innerHTML.replace("<BR>", " "))}

$questionArray = New-Object System.Collections.Generic.List[System.Object]
$imageArray = New-Object System.Collections.Generic.List[System.Object]
$image = ""
foreach ($val in $array){
    #write-host $val 
    #write-host " "
    $amount = $val -match "FONT"
    if($amount){
        if($val -match "META content"){
            $fix = ""
            $fix = $val -split '<SPAN'
            $val = $fix[0]
        }

        $val = $val.replace("<FONT color=#333333>","")
        $val = $val.replace("</FONT>","")
        $answer = $val
    }
    $testExplain = $val -match "Explanation"
    if($testExplain){
        $explaination = $val
    }

    $imageTest = $val -match "href"
    if($imageTest){
            $imageArray.Add($val)
          
    }
    
    $questionTest = $val -match '^[A-Z]\.'
    if($questionTest){
        $questionArray.Add($val)}
    
}
$questions = ""
foreach ($question in $questionArray){
    #write-host $question
    #write-host " "
    if($question -match "<META content="){
            $fix = ""
            $fix = $question -split '<SPAN'
            $question = $fix[0]
    }
    $questions = $questions + "<br>" + $question + "<br>"
    

   
}

if($url -match "cisco"){
$final = $array[0] + "<br>" + $imageArray[0] + "<br>" + $questions + "`t" + $answer + "<br><br>" + $explaination
}else{
$final = $array[0] + "<br>" + $imageArray[0] + "<br>" + $questions + "`t" + $answer
}

$final = $final.replace("<FONT color=#333333>","")
$final = $final.replace("</FONT>","")

# Debugging for final string before writing to file
#write-host $array

#write-host $questions
#write-host " "
#write-host $answer
#write-host " "
#write-host $final


Out-File -Filepath c:\temp\test.txt -InputObject $final -Append -Encoding UTF8

#write-host $array[5]

}
