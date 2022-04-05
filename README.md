# TotalAgility Product Container Files

These are the sample scripts for installing TotalAgility in docker which are provided with the product in (Install Source)\Utilities\Docker.  

The intent of adding them here is to use the commit diffs to see changes in the samples between versions.  Since it is common to customize scripts to the needs of an environment, it can be helpful to see these changes.  If the changes are minor it might make sense to manually apply them to customized scripts when building containers for a new version.  If the changes are larger, it might make sense to start with the updated samples and apply the customizations on top.

In addition to the powershell scripts, the sample XML file used for the KTA silent install is also included, as this is used when the scripts trigger the KTA install during container build.  Similar to the scripts, there might be changes between versions that are worth adding to an existing configuration when building containers on a new version.  But it should be noted that these are general samples for silent install configuration, and not all settings are applicable to containers, as shown in the install guide.  The separate example XML files are included from the OP, OPMT, and IS builds, as well as the Tenant Management System install.

## KTA 7.9 to 7.10

* [Powershell](https://github.com/smklancher/TotalAgilityProductContainerFiles/commit/dc6a4cf5bafc8cd83555e9962d581d3140662b66)
* [Silent install XML](https://github.com/smklancher/TotalAgilityProductContainerFiles/commit/dc6a4cf5bafc8cd83555e9962d581d3140662b66#diff-ee9b5fd13c68c3a5443589ebd31368737dd15c0c830192c095246692d3e35cba)

## KTA 7.8 to 7.9

* [Powershell](https://github.com/smklancher/TotalAgilityProductContainerFiles/commit/9e04b9e4fb75fb93a8ce8af1a21e61e93eb88d41)
* [Silent install XML](https://github.com/smklancher/TotalAgilityProductContainerFiles/commit/f8ed9a545b4aa9968ee0fd506f237b4df6feaee2)

## KTA 7.7 to 7.8

* [Powershell](https://github.com/smklancher/TotalAgilityProductContainerFiles/commit/98f37a23601911cc5713b9f76d72bd326dd63317)
* [Silent install XML](https://github.com/smklancher/TotalAgilityProductContainerFiles/commit/4eeb54e9c42249787a640a1ecefcfa5ece143efa)
