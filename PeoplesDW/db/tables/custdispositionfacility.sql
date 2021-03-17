--
-- $Id$
--
create table custdispositionfacility
(custid                          varchar2(10) not null
,disposition                     varchar2(10) not null
,facility                        varchar2(3) not null
,sortationloc                    varchar2(10)
,lastuser varchar2(12)
,lastupdate date
);

exit;
