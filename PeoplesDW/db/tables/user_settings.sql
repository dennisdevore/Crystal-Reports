create table user_settings (
    userid      varchar(12),
    formid      varchar2(100),
    name        varchar2(100),
    value       varchar2(255),
 constraint user_settings_pk primary key (userid, formid, name)
);

exit;
