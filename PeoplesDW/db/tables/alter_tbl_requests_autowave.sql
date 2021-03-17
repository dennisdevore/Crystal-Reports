alter table requests add(
    date07      date,
    date08      date,
    date09      date,
    date10      date,
    num09       number(12,2),
    num10       number(12,2),
    flag11      varchar2(1),
    flag12      varchar2(1),
    flag13      varchar2(1),
    flag14      varchar2(1),
    flag15      varchar2(1),
    flag16      varchar2(1),
    flag17      varchar2(1),
    flag18      varchar2(1));


update requests
   set
        flag11 = 'N',
        flag12 = 'N',
        flag13 = 'N',
        flag14 = 'N',
        flag15 = 'N',
        flag16 = 'N',
        flag17 = 'N',
        flag18 = 'N'
 where reqtype = 'WaveSelect'
   and flag18 is null;

exit;

