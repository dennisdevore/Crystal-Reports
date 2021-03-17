create or replace view lawson_hdr
(
    postdate,
    prefix,
    invoice,
    facility,
    custid,
    invoicedate,
         glid
)
as
select distinct
    to_char(postdate,'YYYYMMDD'),
    prefix,
    invoice,
    facility,
    custid,
    to_char(invoicedate,'YYYYMMDD'),
         glid
  from lawsonhdrex;

comment on table lawson_hdr is '$Id';

create or replace view lawson_dtl
(
    prefix,
    invoice,
    linenumber,
    facility,
    item,
    descr,
    quantity,
    price,
    uom,
    glaccount,
    araccount
)
as
select distinct
    prefix,
    invoice,
    linenumber,
    facility,
    nvl(item,'ACT'||activity),
    descr,
    substr(to_char(quantity*10000,'09999999999999999'),2),
    decode(sign(price),
        -1,to_char(price*100000,  '09999999999999999'),
        substr(to_char(price*100000,  '099999999999999999'),2)),
    uom,
    glaccount,
    araccount
  from lawsondtlex;

comment on table lawson_dtl is '$Id';

create or replace view lawson_dtlex
(
    prefix,
    invoice,
    linenumber,
    orderid,
    activity,
    activitydesc,
    reference,
    po
)
as
select distinct
    prefix,
    invoice,
    linenumber,
    orderid,
    activity,
    activitydesc,
    reference,
    po
  from lawsondtlex;

comment on table lawson_dtlex is '$Id';

create or replace view lawson_cmt
(
    prefix,
    invoice,
    linenumber,
    sequence,
    comment1
)
as
select distinct
    prefix,
    invoice,
    linenumber,
    sequence,
    comment1
  from lawsoncmtex;

comment on table lawson_cmt is '$Id';

exit;
