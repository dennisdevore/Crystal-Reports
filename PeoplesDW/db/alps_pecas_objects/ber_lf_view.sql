create or replace function ber_lf_view_pq
(
	in_lpid  varchar2,
  	in_rank  number,
   in_type  varchar2
)
return number
is
--
-- $Id: ber_lf_view.sql 22 2005-06-23 21:21:27Z ed $
--
   l_pieces number := 0;
   l_quantity number := 0;
	l_cnt number := 0;
begin
  for lfd in (select pieces, sum(quantity) as quantity
                  from load_flag_dtl
                  where lpid = in_lpid
                  group by pieces
                  order by pieces desc)
   loop
      l_cnt := l_cnt + 1;
      if l_cnt >= in_rank then
         l_pieces := lfd.pieces;
         l_quantity := lfd.quantity;
         exit;
      end if;
   end loop;

   if in_type = 'P' then
      return l_pieces;
   else
      return l_quantity;
   end if;
end ber_lf_view_pq;
/


create or replace view ber_lf_view
(
   lpid,
   p1,
   p2,
   q1,
   q2,
   type,
   box,
   jobno,
   custid,
   status,
   skidno,
   total_skid,
   sack_range,
   skid_vol,
   skid_weight,
   total_sack,
   load_no,
   cnt_type,
   created,
   name,
   orderid,
   shipid,
   item,
   weight,
   qtyorder,
   shiptoname,
   shiptocontact,
   shiptoaddr1,
   shiptoaddr2,
   shiptocity,
   shiptostate,
   shiptopostalcode,
   shiptophone,
   hdrpassthruchar01,
   hdrpassthruchar02,
   hdrpassthruchar03,
   hdrpassthruchar04,
   hdrpassthruchar05,
   hdrpassthruchar06,
   hdrpassthruchar07,
   hdrpassthruchar08,
   hdrpassthruchar09,
   hdrpassthruchar10,
   hdrpassthruchar11,
   hdrpassthruchar12,
   hdrpassthruchar13,
   hdrpassthruchar14,
   hdrpassthruchar15,
   hdrpassthruchar16,
   hdrpassthruchar17,
   hdrpassthruchar18,
   hdrpassthruchar19,
   hdrpassthruchar20,
   hdrpassthrunum01,
   hdrpassthrunum02,
   hdrpassthrunum03,
   hdrpassthrunum04,
   hdrpassthrunum05,
   hdrpassthrunum06,
   hdrpassthrunum07,
   hdrpassthrunum08,
   hdrpassthrunum09,
   hdrpassthrunum10,
   hdrpassthrudate01,
   hdrpassthrudate02,
   hdrpassthrudate03,
   hdrpassthrudate04,
   po,
   shiptype,
   arrivaldt
)
as
select distinct
   LH.lpid,
   ber_lf_view_pq(LH.lpid,1,'P'),
   ber_lf_view_pq(LH.lpid,2,'P'),
   ber_lf_view_pq(LH.lpid,1,'Q'),
   ber_lf_view_pq(LH.lpid,2,'Q'),
   LH.type,
   LH.facility,
   LH.jobno,
   LH.custid,
   LH.status,
   LH.skidno,
   LH.total_skid,
   LH.sack_range,
   LH.skid_vol,
   LH.skid_weight,
   LH.total_sack,
   LH.load_no,
   LH.cnt_type,
   LH.created,
   CU.name,
   LD.orderid,
   LD.shipid,
   LD.item,
   LD.weight,
   OH.qtyorder,
   OH.shiptoname,
   OH.shiptocontact,
   OH.shiptoaddr1,
   OH.shiptoaddr2,
   OH.shiptocity,
   OH.shiptostate,
   OH.shiptopostalcode,
   OH.shiptophone,
   OH.hdrpassthruchar01,
   OH.hdrpassthruchar02,
   OH.hdrpassthruchar03,
   OH.hdrpassthruchar04,
   OH.hdrpassthruchar05,
   OH.hdrpassthruchar06,
   OH.hdrpassthruchar07,
   OH.hdrpassthruchar08,
   OH.hdrpassthruchar09,
   OH.hdrpassthruchar10,
   OH.hdrpassthruchar11,
   OH.hdrpassthruchar12,
   OH.hdrpassthruchar13,
   OH.hdrpassthruchar14,
   OH.hdrpassthruchar15,
   OH.hdrpassthruchar16,
   OH.hdrpassthruchar17,
   OH.hdrpassthruchar18,
   OH.hdrpassthruchar19,
   OH.hdrpassthruchar20,
   OH.hdrpassthrunum01,
   OH.hdrpassthrunum02,
   OH.hdrpassthrunum03,
   OH.hdrpassthrunum04,
   OH.hdrpassthrunum05,
   OH.hdrpassthrunum06,
   OH.hdrpassthrunum07,
   OH.hdrpassthrunum08,
   OH.hdrpassthrunum09,
   OH.hdrpassthrunum10,
   OH.hdrpassthrudate01,
   OH.hdrpassthrudate02,
   OH.hdrpassthrudate03,
   OH.hdrpassthrudate04,
   OH.po,
   OH.shiptype,
   to_char(OH.arrivaldate, 'MM-DD-YY')
from load_flag_hdr LH,
     customer CU,
     load_flag_dtl LD,
     orderhdr OH
where LH.created >= sysdate-60
  and CU.custid = LH.custid
  and LD.lpid = LH.lpid
  and OH.orderid = LD.orderid
  and OH.shipid = LD.shipid;

comment on table ber_lf_view is '$Id: ber_lf_view.sql 22 2005-06-23 21:21:27Z ed $';

exit;
