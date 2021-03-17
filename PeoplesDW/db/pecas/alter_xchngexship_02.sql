--
-- $Id$
--
alter table XchngExShipHdr 
modify (
    passthru06      varchar2(60),
    passthru07      varchar2(60),
    passthru08      varchar2(60),
    passthru09      varchar2(60)
)
add(
    passthru11      varchar2(60),
    passthru12      varchar2(60)
);
