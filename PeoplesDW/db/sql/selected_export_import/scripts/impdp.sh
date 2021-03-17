impdp ${ALPS_DBLOGON} directory=dumpdir dumpfile=prod.dmp transform=storage:n
. ~/sql/start_all_qs.sh
recomp
cd ~/sql
sqlf start_jobs
start_sys
cd - >/dev/null

