alter table multishiphdr add(massman char(1));

update multishiphdr
  set massman = 'N';

commit;

update multishiphdr
   set massman = 'Y'
where (orderid, shipid) in
(
select O.orderid, O.shipid
  from waves W, orderhdr O, multishiphdr H
 where O.orderid = H.orderid
   and O.shipid = H.shipid
   and W.wave = O.wave
   and W.mass_manifest = 'Y'
);

commit;


exit;
