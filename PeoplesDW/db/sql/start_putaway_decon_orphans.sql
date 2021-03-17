declare
   l_job number;
begin
   dbms_job.submit(job        => l_job,
                   what       => 'zput.putaway_decon_orphans;',
                   next_date  => sysdate,
                   interval   => 'sysdate+1/24/4');
end;
/
exit;
