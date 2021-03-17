--
-- $Id$
--
set serveroutput on;
declare
out_msg varchar2(255);
qtyAllocable number(16);

begin
out_msg := '';
/*
select zcm.in_str_clause('I', 'AA,BB,CC')
  into out_msg
  from dual;
zut.prt('>' || out_msg || '<');
select zcm.in_str_clause('E', 'QC')
  into out_msg
  from dual;
zut.prt('>' || out_msg || '<');
*/
qtyAllocable := zcm.allocable_qty
('001' -- facility
,'ONE' -- custid
,121   -- orderid
,1     -- shipid
,'1'   -- item
,'EA'  -- uom
,''    -- lot
,''    -- status indicator
,''    -- status values
,''    -- class indicator
,''    -- class values
);
zut.prt('>' || qtyAllocable || '<');
qtyAllocable := zcm.order_allocable_qty
('001' -- facility
,'ONE' -- custid
,121   -- orderid
,1     -- shipid
);
zut.prt('>' || qtyAllocable || '<');
end;
/
exit;