create or replace view berlin_bill_hdr
(invoice
,d_invoice
,postdate
,postmonth
,postyear
,facility
,custid
,description
,amount
,doctype
)
as
select
    invoice,
    '"'||to_char(invoice)||'"',
    postdate,
    to_char(postdate,'MM'),
    to_char(postdate,'YYYY'),
    facility,
    '"'||custid||'"',
    case when instr(description,' ') > 0 then
      description
      else
      '"'||description||'"'
    end,
    to_char(amount,'FM9999999.90'),
    decode(sign(amount), -1, '"CR2"','"IN1"')
  from posthdr;
  
comment on table berlin_bill_hdr is '$Id$';
exit;


