--
-- $Id: import_204_stop.sql 1 2005-05-26 12:20:03Z ed $
--
create table import_204_stop
(importfileid varchar2(255)
,seq varchar2(9)
,func varchar2(2)
,shipmentid varchar2(40)
,stop number(7)
,delappt_date varchar2(255)
,delappt_time varchar2(255)
,comment1 clob
,date_format varchar2(255)
,created timestamp
);
create index import_204_stop_idx
on import_204_stop(importfileid, seq);

exit;


