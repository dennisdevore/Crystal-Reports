--
-- $Id: custitemgallery.sql 8451 2012-05-18 18:26:46Z ed $
--
create table custitemgallery (
   custid      varchar2(10) not null,
	item varchar2(50) not null,
   uom         varchar2(4),
   image       blob,
   filetype    varchar2(12),
   lastuser    varchar2(12),
	lastupdate  date
);

create unique index custitemgallery_unique
   on custitemgallery (custid, item, uom);

exit;
