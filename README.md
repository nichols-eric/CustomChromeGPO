Chrome extensions do not enable "Allow access to file URL's" through native scripting, Manifest or GPO.
I threw this powershell script and GPO template together to address my need.
The registry key could be set by other means, sample provided.
I chose to use powershell to modify all users chrome preferences files but ideally this would be done
using a Group Policy Client Side Extension. Even better would be Google add this capability to its set
of Group Policy templates. Please.