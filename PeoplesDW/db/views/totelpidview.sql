CREATE OR REPLACE VIEW ALPS.TOTELPIDVIEW 
(
    LPID,
    TOTELPID
)
AS
select S.lpid LPID,
       T.lpid TOTELPID
  from shippingplate S,
       plate C,
       plate T
 where S.lpid = C.fromshippinglpid
   and C.parentlpid = T.lpid
   and T.type = 'TO'
   and S.type <> 'C'
union
select S.lpid LPID,
       S.totelpid TOTELPID
  from shippingplate S
 where S.type = 'C';
 
comment on table TOTELPIDVIEW is '$Id$';
 
exit;
