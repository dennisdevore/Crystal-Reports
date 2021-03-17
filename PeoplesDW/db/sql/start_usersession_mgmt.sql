declare
   l_job number;
begin
   dbms_job.submit(job        => l_job,
                   what       => 'usersession_mgmt;',
                   next_date  => sysdate,
                   interval   => 'sysdate+1/24/12');
end;
/
exit;
