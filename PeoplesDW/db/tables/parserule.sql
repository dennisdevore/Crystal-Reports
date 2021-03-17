--
-- $Id$
--
create table parserule
(
    ruleid              varchar2(10) not null,
    descr               varchar2(32),
    serialnomask        varchar2(30),
    lotmask             varchar2(30),
    user1mask           varchar2(30),
    user2mask           varchar2(30),
    user3mask           varchar2(30),
    mfgdatemask         varchar2(30),
    expdatemask         varchar2(30),
    countrymask         varchar2(30),
    lastuser            varchar2(12),
    lastupdate          date
);

--exit;
