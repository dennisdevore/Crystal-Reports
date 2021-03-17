create or replace view customcodeview(businessevent, descr, code)
as
select C.businessevent,
       B.descr,
       C.code
 from businessevents B, customcode C
 where C.businessevent = B.code;
 
comment on table customcodeview is '$Id$';
 
exit;
 
