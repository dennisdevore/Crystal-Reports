declare
   l_job number;
begin
   dbms_job.submit(job        => l_job,
                   what       => 'zapstatistics;',
                   next_date  => trunc(sysdate)+1+1/24/4,
                   interval   => 'sysdate+1');
end;
/
exit;
