--
-- $Id$
--
drop table mass_manifest_ctn;

create table mass_manifest_ctn
(
   ctnid     varchar2(15),
   orderid   number(7),
   shipid    number(2),
   item varchar2(50),
   lotnumber varchar2(30),
   seq       number(7),
   seqof     number(7),
   used      char(1),
   wave      number(9)
);

create unique index mass_manifest_ctn_idx
on mass_manifest_ctn(ctnid);

create index mass_manifest_ctn_item
on mass_manifest_ctn(orderid, shipid, item);

create index mass_manifest_ctn_wave
on mass_manifest_ctn(wave);

exit;
