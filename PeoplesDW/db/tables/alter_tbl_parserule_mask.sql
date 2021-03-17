--
-- $Id: alter_tbl_parserule_mask.sql 9643 2013-03-06 18:50:44Z ed $
--
alter table parserule modify
(
    serialnomask        varchar2(50),
    lotmask             varchar2(50),
    user1mask           varchar2(50),
    user2mask           varchar2(50),
    user3mask           varchar2(50),
    mfgdatemask         varchar2(50),
    expdatemask         varchar2(50),
    countrymask         varchar2(50)
);

exit;
