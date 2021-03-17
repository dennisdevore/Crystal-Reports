create table taskhistory
(whenoccurred      timestamp(9),
 taskid            number(15),
 tasktype          varchar2(2),
 facility          varchar2(3),
 fromsection       varchar2(10),
 fromloc           varchar2(10),
 fromprofile       varchar2(2),
 tosection         varchar2(10),
 toloc             varchar2(10),
 toprofile         varchar2(2),
 touserid          varchar2(10),
 custid            varchar2(10),
 item              varchar2(20),
 lpid              varchar2(15),
 uom               varchar2(4),
 qty               number(7),
 locseq            number(7),
 loadno            number(7),
 stopno            number(7),
 shipno            number(7),
 orderid           number(9),
 shipid            number(2),
 orderitem         varchar2(20),
 orderlot          varchar2(30),
 priority          varchar2(1),
 prevpriority      varchar2(1),
 curruserid        varchar2(10),
 lastuser          varchar2(12),
 lastupdate        date,
 pickuom           varchar2(4),
 pickqty           number(7),
 picktotype        varchar2(4),
 wave              number(9),
 pickingzone       varchar2(10),
 cartontype        varchar2(4),
 weight            number(13,4),
 cube              number(10,4),
 staffhrs          number(10,4),
 cartonseq         number(4),
 clusterposition   varchar2(6),
 convpickloc       varchar2(10),
 step1_complete    char(1));

create index taskhistory_wave_idx on taskhistory(wave) tablespace users16kb;

create index taskhistory_date_idx on taskhistory(whenoccurred) tablespace users16kb;

exit;
