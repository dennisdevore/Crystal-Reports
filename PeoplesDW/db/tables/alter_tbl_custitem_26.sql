--
-- $Id$
--
alter table custitem add (
    nmfc_article        varchar2(15),
    tms_uom             varchar2(4),
    tms_commodity_code  varchar2(30)
);

exit;

