--
-- $Id: parselookup.sql 1 2005-08-03 12:20:03Z ron $
--
create table parselookup
(
    ruleid              varchar2(10) not null,
    lookupid            varchar2(1) not null,
    tableid             varchar2(32) not null,
    in_len              number(2),
    out_len             number(2),
    mask                varchar2(20),
    lastuser            varchar2(12),
    lastupdate          date
);

create unique index parselookup_idx on parselookup(ruleid, lookupid);
-- exit;
