#/bin/bash

su -c "/usr/lib/postgresql/10/bin/postgres -D /var/lib/postgresql/10/main -c config_file=/etc/postgresql/10/main/postgresql.conf &" postgres
dotnet out/A2882.dll