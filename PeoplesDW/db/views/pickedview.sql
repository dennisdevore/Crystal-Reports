create or replace view pickedview
(
    taskid,
    custid,
    facility,
    location,
    qtyentered,
    fromlpid
)
as
select
    SP.taskid,
    SP.custid,
    SP.facility,
    SP.location,
    SP.quantity,
    SP.fromlpid
  from shippingplate SP
 where SP.parentlpid is null
   and SP.status = 'P'
union
select
    P.taskid,
    P.custid,
    P.facility,
    P.location,
    P.quantity,
    P.lpid
  from plate P
 where P.type = 'TO';
 
comment on table pickedview is '$Id$';
 
exit;
