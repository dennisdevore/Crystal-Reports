--
-- $Id$
--
alter table XchngExShipHdr add (
    passthru06      varchar2(40),
    passthru07      varchar2(40),
    passthru08      varchar2(40),
    passthru09      varchar2(40),
    shiptocontact   varchar2(40)
);
