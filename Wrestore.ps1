do {$base = read-host "Database name"
    $day = read-host "Day to restore as 20201231"
    if  ((Test-Path C:\pgbackup\$base$day.bak) -eq $false){
        echo "Check the database name and date to restore. C:\pgbackup\$base$day.bak is not found"
    }
} until (Test-Path C:\pgbackup\$base$day.bak)
do {$newbase = read-host "New database name"
    foreach ($s in psql -U postgres --list | select -Skip 3 | Select -SkipLast 7 ){
        $database = $s.split(" ")[1]
        if ($newbase -eq $database) {
            $exist = $true
            $enter = read-host "database $newbase already exists, rewrite?"
        }
    }
} until (($exist -ne $true) -or (($exist -eq $true) -and (($enter -eq "yes") -or ($enter -eq "y"))))

if ((($enter -eq "yes") -or ($enter -eq "y"))) {
    psql -U postgres -c "UPDATE pg_database SET datallowconn = 'false' WHERE datname = '$base';"
    psql -U postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$base' AND pid <> pg_backend_pid();" > $null
    echo "Droping $base and creating $newbase..."
    dropdb -U postgres $base
    createdb -U postgres $newbase
    echo "Restoring C:\pgbackup\$base$day.bak to $newbase..."
    $ts = Measure-Command -Expression {pg_restore -j 12 -d $newbase -U postgres C:\pgbackup\$base$day.bak}
}
if ($exist -ne $true){
    echo "Creating $newbase..."
    createdb -U postgres $newbase
    echo "Restoring C:\pgbackup\$base$day.bak to $newbase..."
    $ts = Measure-Command -Expression {pg_restore -j 12 -d $newbase -U postgres C:\pgbackup\$base$day.bak}
}
echo "Lapsed time is $ts"