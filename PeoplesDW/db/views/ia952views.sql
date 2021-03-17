create or replace view ia952hdr
(
   custid,
   idcode,
   facilityid,
   soldto,
   shipto,
   transactiondate
)
as
   select custid,
          '01' idcode,
          '118' facilityid,
          'soldto' soldto,
          'shipto' shipto,
          sysdate transactiondate
     from customer;

create or replace view ia952dtl
(
   custid,
   facilityid,
   idcode,
   item,
   upc,
   gtin,
   description,
   lotnumber,
   rsncode,
   baseuom,
   baseqty,
   eauom,
   eaqty
)
as
   select custid,
          facility,
          '04',
          item,
          upc,
          (select substr (u.itemalias, 1, 14)
             from custitemalias u
            where u.custid = i.custid and
                  u.item = i.item  and
                  u.aliasdesc like 'gtin%' and
                  rownum = 1), -- gtin
          lpid, -- description
          nvl (lotnumber, '(none)'), -- lotnumnber
          rsncode,
          uom,
          quantity,
          'EA',
          decode (zlbl.uom_qty_conv(i.custid,i.item, i.uom, 'EA', nvl (quantity, 0)), 0, nvl (quantity, 0),
                         zlbl.uom_qty_conv(i.custid,i.item, i.uom, 'EA', nvl (quantity, 0)))
     from invadj947dtlex i
    where quantity <> 0 and sessionid = '80171';

exit;

