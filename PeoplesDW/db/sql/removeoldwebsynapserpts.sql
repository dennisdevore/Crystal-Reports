delete  from tbl_user_permissions
where action = 17 or action = 18;
delete  from tbl_report_types
where action = 17 or action = 18;
commit;
exit;