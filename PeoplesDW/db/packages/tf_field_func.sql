CREATE OR REPLACE FUNCTION TF_FIELD (in_orderid number, in_shipid number, in_orderitem varchar2, in_orderlot varchar2, in_fieldname varchar2)
return varchar2 is
strTFField varchar2(255);
begin
strTFField := null;

if(upper(in_fieldname) not in ('DTLPASSTHRUCHAR01',
                               'ITMPASSTHRUCHAR02',
                               'HDRPASSTHRUNUM02',
                               'HDRPASSTHRUNUM06')) then
  select substr (sys_connect_by_path (order_field, ','), 2) csv
    into strTFField
    from (select order_field,
                 row_number () over (order by order_field ) rn,
                 count (*) over () cnt
            from (select distinct decode(upper(in_fieldname),
                                         'HDRPASSTHRUCHAR02',hdrpassthruchar02,
                                         'HDRPASSTHRUCHAR08',hdrpassthruchar08,
                                         'HDRPASSTHRUNUM01',nvl(hdrpassthruchar60,to_char(hdrpassthrunum01)),
                                         'PO',po,
                                         null) order_field
                    from orderhdr
                   where (orderid,shipid) in
                   (select orderid,shipid
                      from plate
                     where lpid in
                     (select fromlpid
                        from shippingplate
                       where orderid = in_orderid
                         and shipid = in_shipid
                         and type in('F','P'))
                     union
                    select orderid,shipid
                      from deletedplate
                     where lpid in
                     (select fromlpid
                        from shippingplate
                       where orderid = in_orderid
                         and shipid = in_shipid
                         and type in('F','P')))))
   where rn = cnt
   start with rn = 1
  connect by rn = prior rn + 1;
elsif(upper(in_fieldname) in ('HDRPASSTHRUNUM02','HDRPASSTHRUNUM06')) then
  select distinct decode(upper(in_fieldname),
                         'HDRPASSTHRUNUM02',to_char(hdrpassthrunum02),
                         'HDRPASSTHRUNUM06',to_char(hdrpassthrunum06),
                         null) order_field
    into strTFField
    from orderhdr
   where (orderid,shipid) in
    (select orderid,shipid
       from plate
      where lpid in
       (select fromlpid
          from shippingplate
         where orderid = in_orderid
           and shipid = in_shipid
           and orderitem = in_orderitem
           and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
           and type in('F','P'))
       union
     select orderid,shipid
       from deletedplate
      where lpid in
       (select fromlpid
          from shippingplate
         where orderid = in_orderid
           and shipid = in_shipid
           and orderitem = in_orderitem
           and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
           and type in('F','P')));
else
  select substr (sys_connect_by_path (order_field, ','), 2) csv
    into strTFField
    from (select order_field,
                 row_number () over (order by order_field ) rn,
                 count (*) over () cnt
            from (select distinct decode(upper(in_fieldname),
                                         'DTLPASSTHRUCHAR01',od.dtlpassthruchar01,
                                         'ITMPASSTHRUCHAR02',ci.itmpassthruchar02,
                                         null) order_field
                    from orderdtl od, custitem ci
                   where od.orderid = in_orderid
                     and od.shipid = in_shipid
                     and ci.custid = od.custid
                     and ci.item = od.item))
   where rn = cnt
   start with rn = 1
  connect by rn = prior rn + 1;
end if;

if(upper(in_fieldname) = 'HDRPASSTHRUCHAR02') then
  strTFField := replace(strTFField,',','/');
end if;

return strTFField;
exception when others then
  return '';
end TF_FIELD;
/
exit;
