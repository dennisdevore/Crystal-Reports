create or replace view topickview
(
    taskid,
    tasktype,
    facility,
    fromloc,
    toloc,
    custid,
    item,
    picklpid,
    qty,
    uom,
    locseq,
    pickuom,
    pickqty,
    picktotype,
    shplpid,
    parentlpid,
    status,
    holdreason,
    type
)
as
select
    ST.taskid,
    ST.tasktype,
    ST.facility,
    ST.fromloc,
    ST.toloc,
    ST.custid,
    ST.item,
    ST.lpid,
    ST.qty,
    ST.uom,
    ST.locseq,
    ST.pickuom,
    ST.pickqty,
    ST.picktotype,
    SP.lpid,
    SP.parentlpid,
    SP.status,
    SP.holdreason,
    SP.type
  from shippingplate SP, subtasks ST
 where ST.tasktype = 'OP'
   and SP.taskid = ST.taskid
   and SP.lpid = ST.shippinglpid
   and SP.status = 'U'
   and not exists
       (select *
          from plate
         where fromshippinglpid = SP.lpid);
         
comment on table topickview is '$Id$';
         
exit;
