# .".\SetVars.ps1"

write-host Drop API User

"drop user $name cascade;`ncommit;`nexit;" | sqlplus $master/$masterpw`@$tns 