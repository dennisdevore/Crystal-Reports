alter table requests add(
    flag19      varchar2(1));


update requests
   set
        flag19 = 'N'
 where reqtype = 'WaveSelect'
   and flag19 is null;

exit;

