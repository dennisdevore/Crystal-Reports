--
-- $Id$
--
drop table load_flag_hdr;
create table load_flag_hdr(
    type        char(1),        -- (D)estinational,
                                -- (S)mall Package, 
                                -- (M)ail List
    facility    varchar2(3),
    jobno       varchar2(10),
    custid      varchar2(10),
    lpid        varchar2(15),
    status      varchar2(10),   -- NEW, PRINTED, RECEIVED
    skidno      number(3),
    total_skid  number(3),
    sack_range  varchar2(20),
    skid_vol    number(16,4),
    skid_weight number(16,4),
    total_sack  number(16,4), 
    load_no     number(10),
    cnt_type    varchar2(10),
    created     date
);

create index load_flag_hdr_job_idx on load_flag_hdr(jobno, custid);
create unique index load_flag_hdr_lpid_idx on load_flag_hdr(lpid);

drop public synonym load_flag_hdr;

create public synonym load_flag_hdr for pecas.load_flag_hdr;

grant insert,update on pecas.load_flag_hdr to alps;
grant select on pecas.load_flag_hdr to alps with grant option;

exit;
