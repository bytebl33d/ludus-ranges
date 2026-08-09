$User = "viserion"
$SSHHost = "syrax.dracarys.lab"
$Password = "aLHtz1WvIVmeV4Zh4CDE"

& "C:\Program Files\PuTTY\klink.exe" -auto_store_sshkey $SSHHost -l "$User" -pw $Password "sleep 45"
