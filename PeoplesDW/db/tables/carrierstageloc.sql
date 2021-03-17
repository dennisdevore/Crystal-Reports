--
-- $Id$
--
create table carrierstageloc
(carrier varchar2(4) not null
,facility varchar2(3) not null
,stageloc varchar2(10) not null
,lastuser varchar2(12)
,lastupdate date
);

exit;
