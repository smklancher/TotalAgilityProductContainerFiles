# Enabling Proxy in IIS
Import-Module WebAdministration;
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/proxy" -name "enabled" -value "True";

# Adding required Rewrite rule to config
# Read OPMT split APP server name from user
{
$opmtapp = Read-Host -Prompt "Enter your On-Premine Multi-Tenancy split APP server container's machine name" ;
$opmtURL = "https://{C:1}."+ $opmtapp +"/TotalAgility/services/core/{R:1}";
}
# Getting opmt web config file and loading it as XML to update it
{
$filename = "C:\Program Files\Kofax\TotalAgility\Agility.Server.Web\Web.config";
$doc = (Get-Content $filename) -as [Xml];
}
# Create new elements and corresponding attribute values for them
{
$newEl3 = $doc.CreateElement("rule");
$newEl4 = $doc.CreateElement("match");
$newEl5 = $doc.CreateElement("action");
$newEl6 = $doc.CreateElement("conditions");
$newEl7 = $doc.CreateElement("add");
$nameAtt1=$doc.CreateAttribute("name");
$nameAtt1.psbase.value="CoreServicesRule";
$nameAtt2=$doc.CreateAttribute("enabled");
$nameAtt2.psbase.value="true";
$nameAtt3=$doc.CreateAttribute("stopProcessing");
$nameAtt3.psbase.value="true";
$nameAtt4=$doc.CreateAttribute("url");
$nameAtt4.psbase.value="Services/Core/(.*)";
$nameAtt5=$doc.CreateAttribute("type");
$nameAtt5.psbase.value="Rewrite";
$nameAtt6=$doc.CreateAttribute("url");
$nameAtt6.psbase.value=$opmtURL;
$nameAtt7=$doc.CreateAttribute("logRewrittenUrl");
$nameAtt7.psbase.value="false";
$nameAtt8=$doc.CreateAttribute("trackAllCaptures");
$nameAtt8.psbase.value="true";
$nameAtt9=$doc.CreateAttribute("input");
$nameAtt9.psbase.value="{HTTP_HOST}";
$nameAtt10=$doc.CreateAttribute("pattern");
$nameAtt10.psbase.value="([^.]*)(.*)";
$newEl7.SetAttributeNode($nameatt9);
$newEl7.SetAttributeNode($nameAtt10);
$newEl6.SetAttributeNode($nameAtt8);
$newEl5.SetAttributeNode($nameAtt5);
$newEl5.SetAttributeNode($nameAtt6);
$newEl5.SetAttributeNode($nameAtt7);
$newEl4.SetAttributeNode($nameAtt4);
$newEl3.SetAttributeNode($nameatt1);
$newEl3.SetAttributeNode($nameatt2);
$newEl3.SetAttributeNode($nameatt3);
}
# Check if rewrite section is commented and create new rewrite section if required
$rewrite = $null;
$rewrite = $doc.SelectNodes("//configuration/system.webServer/rewrite");
if ($rewrite -eq $null)
{
    $newEl1 = $doc.CreateElement("rewrite");
    $newEl2 = $doc.CreateElement("rules");
    $doc.configuration.'system.webServer'.AppendChild($newEl1);
    $doc.SelectSingleNode("//configuration/system.webServer/rewrite").AppendChild($newEl2);
}
# Creating the rule
$doc.SelectSingleNode("//configuration/system.webServer/rewrite/rules").PrependChild($newEl3);
$doc.SelectSingleNode("//configuration/system.webServer/rewrite/rules/rule").AppendChild($newEl4);
$doc.SelectSingleNode("//configuration/system.webServer/rewrite/rules/rule/match").AppendChild($newEl5);
$doc.SelectSingleNode("//configuration/system.webServer/rewrite/rules/rule/match").AppendChild($newEl6);
$doc.SelectSingleNode("//configuration/system.webServer/rewrite/rules/rule/match/conditions").AppendChild($newEl7);
# Saving the file
$doc.Save($filename);