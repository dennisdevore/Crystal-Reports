--
-- $Id$
--
drop table palletinventory cascade constraints ; 

create table palletinventory ( 
  custid      varchar2 (10)  not null, 
  facility    varchar2 (3)  not null, 
  pallettype  varchar2 (12)  not null, 
  cnt         number (7)    not null);

exit;

