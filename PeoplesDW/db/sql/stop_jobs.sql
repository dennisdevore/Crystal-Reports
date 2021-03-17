exec zjob.stop_daily_billing;
exec zjob.stop_alert_process;
exec zjob.stop_daily_jobs;
exec zjob.stop_late_trailer_check;
commit;
exit;