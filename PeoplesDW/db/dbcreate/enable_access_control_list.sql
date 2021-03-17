alter system set smtp_out_server='smtp.client.com:25' scope=both;

create pfile from spfile;

grant execute on sys.utl_mail to alps;
grant execute on sys.utl_tcp to alps;
grant select on sys.dba_data_files to alps;

execute dbms_network_acl_admin.drop_acl('acl_for_alps.xml');
commit;
execute dbms_network_acl_admin.create_acl('acl_for_alps.xml', 'acl for alps job','ALPS', true, 'connect');
commit;
execute dbms_network_acl_admin.assign_acl('acl_for_alps.xml','smtp.client.com', 25);
commit;
execute dbms_network_acl_admin.add_privilege('acl_for_alps.xml','ALPS', true, 'connect');
commit;

grant execute on sys.utl_smtp to alps;

SELECT host,lower_port,upper_port,acl,DECODE(DBMS_NETWORK_ACL_ADMIN.check_privilege_aclid(aclid, 'ALPS', 'connect'),1, 'GRANTED', 0, 'DENIED', null) PRIVILEGE
FROM dba_network_acls
WHERE host IN (SELECT * FROM TABLE(DBMS_NETWORK_ACL_UTILITY.domains('smtp.client.com')))
ORDER BY DBMS_NETWORK_ACL_UTILITY.domain_level(host) desc, lower_port, upper_port;

SELECT acl,principal,privilege,is_grant,TO_CHAR(start_date, 'DD-MON-YYYY') AS start_date,TO_CHAR(end_date, 'DD-MON-YYYY') AS end_date
FROM dba_network_acl_privileges;

select host, lower_port, upper_port, acl,DBMS_NETWORK_ACL_ADMIN.CHECK_PRIVILEGE_ACLID(aclid,null,'connect') GRANTED from dba_network_acls;
exit;

