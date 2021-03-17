create or replace package  body zpallettrack
IS
--
-- $Id$
--
procedure add_pallet_history (in_custid varchar2
                                ,in_carrier varchar2
                                ,in_facility varchar2
                                ,in_pallettype varchar2
                                ,in_inpallets integer
                                ,in_outpallets integer
                                ,in_adjreason varchar2
                                ,in_comment varchar2
                                ,in_orderid integer
                                ,in_shipid integer
                                ,in_loadno integer
                                ,in_lastuser varchar2) is
begin
insert  into pallethistory (custid,carrier,
             facility,pallettype,inpallets,outpallets,adjreason,comment1,
             orderid,shipid,loadno,lastuser,lastupdate)
        values(in_custid,in_carrier,
             in_facility,in_pallettype,in_inpallets,in_outpallets,in_adjreason,in_comment,
             in_orderid,in_shipid,in_loadno,in_lastuser,sysdate);
end add_pallet_history;


procedure check_load_complete(
          in_loadno IN number,
          out_errmsg IN OUT varchar2)
is
  CURSOR C_CUSTS(in_loadno number)
  IS
    select distinct H.custid
      from customer C, orderhdr H
     where H.loadno = in_loadno
       and C.custid = H.custid
       and C.trackpallets = 'Y'
       and H.ordertype <> 'F'
       and H.custid not in
       (select custid
          from pallethistory
         where loadno = H.loadno);

BEGIN
  out_errmsg := 'OKAY';

  for crec in C_CUSTS(in_loadno) loop
      if out_errmsg = 'OKAY' then
         out_errmsg := 'Did not enter pallet history for ' || crec.custid;
      else
         out_errmsg := out_errmsg || ', ' || crec.custid;

      end if;
  end loop;
END check_load_complete;

FUNCTION calc_cust_begbal(
    in_custid varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number
IS
  bal number;
  tot number;

 CURSOR C_BAL IS
   select sum(nvl(inpallets,0) - nvl(outpallets,0))
     from pallethistory_sum_cust
    where custid = in_custid
      and facility = in_facility
      and pallettype = in_pallettype
      and trunc_lastupdate >= in_curdate;

 CURSOR C_CUR IS
   select sum(nvl(inpallets,0) - nvl(outpallets,0))
     from pallethistory_sum_cust
    where custid = in_custid
      and facility = in_facility
      and pallettype = in_pallettype;

BEGIN
  
  bal := 0;
  tot := 0;

  OPEN C_CUR;
  FETCH C_CUR into tot;
  CLOSE C_CUR;
  if tot is null then
    tot := 0;
  end if;
  

  OPEN C_BAL;
  FETCH C_BAL into bal;
  CLOSE C_BAL;
  if bal is null then
    bal := 0;
  end if;
  

  return tot - bal;

END calc_cust_begbal;

FUNCTION calc_cust_endbal(
    in_custid varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number
IS
  bal number;
  tot number;

 CURSOR C_BAL IS
   select sum(nvl(inpallets,0) - nvl(outpallets,0))
     from pallethistory_sum_cust
    where custid = in_custid
      and facility = in_facility
      and pallettype = in_pallettype
      and trunc_lastupdate > in_curdate;

 CURSOR C_CUR IS
   select sum(nvl(inpallets,0) - nvl(outpallets,0))
     from pallethistory_sum_cust
    where custid = in_custid
      and facility = in_facility
      and pallettype = in_pallettype;

BEGIN
  bal := 0;
  tot := 0;

  OPEN C_CUR;
  FETCH C_CUR into tot;
  CLOSE C_CUR;
  if tot is null then
    tot := 0;
  end if;
  
  OPEN C_BAL;
  FETCH C_BAL into bal;
  CLOSE C_BAL;
  if bal is null then
    bal := 0;
  end if;
  
  return tot - bal;

END calc_cust_endbal;


FUNCTION calc_carr_begbal(
    in_carrier varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number
IS


  bal number;
  tot number;

 CURSOR C_BAL IS
   select sum(inpallets - outpallets)
     from pallethistory a, orderhdr b
    where a.orderid = b.orderid and
     	  a.shipid = b.shipid and
    	  a.carrier = in_carrier
      and a.facility = in_facility
      and a.pallettype = in_pallettype
      and trunc(a.lastupdate) >= in_curdate;

 CURSOR C_CUR IS
   select sum(inpallets - outpallets)
     from pallethistory a
    where
    	carrier = in_carrier
      and facility = in_facility
      and pallettype = in_pallettype;


BEGIN
  bal := 0;
  tot := 0;

  OPEN C_CUR;
  FETCH C_CUR into tot;
  CLOSE C_CUR;

  OPEN C_BAL;
  FETCH C_BAL into bal;
  CLOSE C_BAL;

  return tot - bal;



END calc_carr_begbal;

FUNCTION calc_carr_endbal(
    in_carrier varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number
IS


  bal number;
  tot number;

 CURSOR C_BAL IS
   select nvl(sum(inpallets - outpallets),0)
     from pallethistory a, orderhdr b
    where a.orderid = b.orderid and
    	   a.shipid = b.shipid and
    	b.carrier = in_carrier
      and a.facility = in_facility
      and a.pallettype = in_pallettype
      and trunc(a.lastupdate) > in_curdate;

 CURSOR C_CUR IS
   select nvl(sum(inpallets - outpallets),0)
     from pallethistory
    where carrier = in_carrier
      and facility = in_facility
      and pallettype = in_pallettype;


BEGIN
  bal := 0;
  tot := 0;

  OPEN C_CUR;
  FETCH C_CUR into tot;
  CLOSE C_CUR;

  OPEN C_BAL;
  FETCH C_BAL into bal;
  CLOSE C_BAL;

  return tot - bal;


END calc_carr_endbal;

FUNCTION calc_cons_begbal(
    in_consignee varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number
IS

  bal number;
  tot number;

 CURSOR C_BAL IS
   select sum(inpallets - outpallets)
     from pallethistory a, orderhdr b
    where  a.orderid = b.orderid and
           a.shipid = b.shipid and
    	   b.consignee = in_consignee
      and a.facility = in_facility
      and a.pallettype = in_pallettype
      and trunc(a.lastupdate) >= in_curdate;

 CURSOR C_CUR IS
   select sum(inpallets - outpallets)
     from pallethistory a, orderhdr b
    where a.orderid = b.orderid and
           a.shipid = b.shipid and
    	  consignee = in_consignee and
           facility = in_facility and
         pallettype = in_pallettype;


BEGIN
  bal := 0;
  tot := 0;

  OPEN C_CUR;
  FETCH C_CUR into tot;
  CLOSE C_CUR;

  OPEN C_BAL;
  FETCH C_BAL into bal;
  CLOSE C_BAL;

  return tot - bal;


END calc_cons_begbal;

FUNCTION calc_cons_endbal(
    in_consignee varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number
IS

  bal number;
  tot number;

 CURSOR C_BAL IS
   select nvl(sum(inpallets - outpallets),0)
     from pallethistory a, orderhdr b
    where  a.orderid = b.orderid and
           a.shipid = b.shipid and
           b.consignee = in_consignee
      and a.facility = in_facility
      and a.pallettype = in_pallettype
      and trunc(a.lastupdate) > in_curdate;

 CURSOR C_CUR IS
   select nvl(sum(inpallets - outpallets),0)
     from pallethistory a, orderhdr b
    where a.orderid = b.orderid and
           a.shipid = b.shipid and
    	  consignee = in_consignee and
           facility = in_facility and
         pallettype = in_pallettype;


BEGIN
  bal := 0;
  tot := 0;

  OPEN C_CUR;
  FETCH C_CUR into tot;
  CLOSE C_CUR;

  OPEN C_BAL;
  FETCH C_BAL into bal;
  CLOSE C_BAL;

  return tot - bal;


END calc_cons_endbal;


FUNCTION sum_outpallets(
in_loadno number,
in_orderid number,
in_shipid number
)
RETURN integer
IS

outpallets pallethistory.outpallets%type;

BEGIN

outpallets := 0;

select sum(outpallets)
  into outpallets
  from pallethistory
 where loadno = in_loadno
   and orderid = in_orderid
   and shipid = in_shipid;

return outpallets;

exception when others then
  return 0;
END sum_outpallets;

end zpallettrack;
/
show error package zpallettrack;
show error package body zpallettrack;
--exit;

