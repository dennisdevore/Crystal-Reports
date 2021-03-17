create or replace view berlin_bill_dtl
(invoice
,d_invoice
,account
,account1
,account2
,description
,amount
,doctype
)
as
select
    D.invoice,
    '"'||to_char(D.invoice)||'"',
    D.account,
    case when instr(substr(D.account,1,6),' ') > 0 then
      substr(D.account,1,6)
      else
      '"'||substr(D.account,1,6)||'"'
    end,
    case when instr(substr(D.account,7,4),' ') > 0 then
      substr(D.account,7,4)
      else
      '"'||substr(D.account,7,4)||'"'
    end,
    case when instr(D.reference,' ') > 0 then
      D.reference
      else
      '"'||D.reference||'"'
    end,
    to_char((D.credit - D.debit),'FM99999.90'),
    decode(sign(H.amount), -1, '"CR2"','"IN1"')
  from posthdr H, postdtl D
  where account not in
    (SELECT substr(defaultvalue,1,40)
      FROM systemdefaults
     WHERE defaultid = 'AR_ACCOUNT')
    and H.invoice = D.invoice;
    
comment on table berlin_bill_dtl is '$Id$';
    
exit;


