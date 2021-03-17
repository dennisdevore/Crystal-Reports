--
-- $Id$
--
set serveroutput on;

declare

out_msg varchar2(255);
out_errorno integer;
out_movement_code varchar2(255);
out_special_stock varchar2(255);
strFromClass varchar2(2);
strToClass varchar2(2);
strFromInvStatus varchar2(2);
strToInvStatus varchar2(2);
strWhse varchar2(4);
strRegWhse varchar2(4);
strRetWhse varchar2(4);
strCustId customer.custid%type;
strReason invadjactivity.adjreason%type;

begin

strCustId := 'HP';
strWhse := 'HPC1';
strFromClass := 'RG';
strFromInvStatus := 'AV';
strToClass := 'RG';
strToInvStatus := 'AV';
strReason := 'PC';
zmi3.get_whse(strCustId,strFromClass,strWhse,strRegWhse,strRetWhse);
zmi3.get_movement_code(
strCustid, -- custid
strWhse, -- warehousest
strFromClass, -- from inventory class
strFromInvStatus, -- from invstatus
strToClass, -- to inventoryclass
strToInvStatus, -- to inventorystatus
strReason, -- reason code
12, -- adj qty
out_movement_code,
out_errorno,
out_msg
);

zut.prt(strCustId || '/' || strWhse || ' ' ||
        strFromClass || '/' || strFromInvStatus || ' ' ||
        strToClass || '/' || strToInvStatus || ' ' ||
        strReason);

zut.prt('movement:>' || out_movement_code || '<');
zut.prt('errorno:  ' || out_errorno);
zut.prt('out_msg:  ' || out_msg);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
