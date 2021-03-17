--
-- $Id: zim8spec.sql 7896 2012-02-02 21:48:59Z jeff $
--
create or replace PACKAGE alps.zimportproc8

Is

procedure begin_loadtender204
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_loadno IN number
,in_send_original_204_yn IN varchar2
,in_pallet_uom IN varchar2
,in_rounding_value IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

procedure end_loadtender204
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

FUNCTION sum_units
(in_orderid IN number,
 in_shipid IN number
) return integer;

FUNCTION sum_volume
(in_orderid IN number,
 in_shipid IN number
) return number;

FUNCTION sum_weight
(in_orderid IN number,
 in_shipid IN number
) return number;

FUNCTION check_orderstatus_for_load
(in_orderid IN number
,in_shipid IN number
) return number;

procedure seteditransaction204
(in_orderid IN number
,in_shipid IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
);

FUNCTION get_systemdefault
(in_defaultid IN varchar2
) return varchar2;

function parseclob
(in_clob in clob
) return sys.odciVarchar2List pipelined;

FUNCTION total_estimated_pallet_count
(in_custid IN varchar2,
 in_orderid IN number,
 in_shipid IN number,
 in_item IN varchar2,
 in_qtyorder IN number,
 in_pallet_uom IN varchar2,
 in_rounding_value IN number
) return number;

FUNCTION total_cases
(in_orderid IN number,
 in_shipid IN number
) return number;

procedure import_inbound204_load
(in_func IN OUT varchar2
,in_facility IN varchar2
,in_shipmentid IN varchar2
,in_carrier IN varchar2
,in_billoflading IN varchar2
,in_custid IN varchar2
,in_shiptype IN varchar2
,in_shipterms IN varchar2
,in_appointmentdate IN date
,in_comment1 IN varchar2
,in_ldpassthruchar01 IN varchar2
,in_ldpassthruchar02 IN varchar2
,in_ldpassthruchar03 IN varchar2
,in_ldpassthruchar04 IN varchar2
,in_ldpassthruchar05 IN varchar2
,in_ldpassthruchar06 IN varchar2
,in_ldpassthruchar07 IN varchar2
,in_ldpassthruchar08 IN varchar2
,in_ldpassthruchar09 IN varchar2
,in_ldpassthruchar10 IN varchar2
,in_ldpassthruchar11 IN varchar2
,in_ldpassthruchar12 IN varchar2
,in_ldpassthruchar13 IN varchar2
,in_ldpassthruchar14 IN varchar2
,in_ldpassthruchar15 IN varchar2
,in_ldpassthruchar16 IN varchar2
,in_ldpassthruchar17 IN varchar2
,in_ldpassthruchar18 IN varchar2
,in_ldpassthruchar19 IN varchar2
,in_ldpassthruchar20 IN varchar2
,in_ldpassthruchar21 IN varchar2
,in_ldpassthruchar22 IN varchar2
,in_ldpassthruchar23 IN varchar2
,in_ldpassthruchar24 IN varchar2
,in_ldpassthruchar25 IN varchar2
,in_ldpassthruchar26 IN varchar2
,in_ldpassthruchar27 IN varchar2
,in_ldpassthruchar28 IN varchar2
,in_ldpassthruchar29 IN varchar2
,in_ldpassthruchar30 IN varchar2
,in_ldpassthruchar31 IN varchar2
,in_ldpassthruchar32 IN varchar2
,in_ldpassthruchar33 IN varchar2
,in_ldpassthruchar34 IN varchar2
,in_ldpassthruchar35 IN varchar2
,in_ldpassthruchar36 IN varchar2
,in_ldpassthruchar37 IN varchar2
,in_ldpassthruchar38 IN varchar2
,in_ldpassthruchar39 IN varchar2
,in_ldpassthruchar40 IN varchar2
,in_ldpassthrudate01 IN date
,in_ldpassthrudate02 IN date
,in_ldpassthrudate03 IN date
,in_ldpassthrudate04 IN date
,in_ldpassthrunum01 IN number
,in_ldpassthrunum02 IN number
,in_ldpassthrunum03 IN number
,in_ldpassthrunum04 IN number
,in_ldpassthrunum05 IN number
,in_ldpassthrunum06 IN number
,in_ldpassthrunum07 IN number
,in_ldpassthrunum08 IN number
,in_ldpassthrunum09 IN number
,in_ldpassthrunum10 IN number
,in_importfileid IN varchar2
,in_seq IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2);

procedure import_inbound204_stop
(in_func IN out varchar2
,in_shipmentid IN varchar2
,in_stop IN number
,in_delappt_date IN varchar2
,in_delappt_time IN varchar2
,in_comment IN varchar2
,in_date_format IN varchar2
,in_importfileid IN varchar2
,in_seq IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2);

procedure import_inbound204_order
(in_func IN out varchar2
,in_shipmentid IN varchar2
,in_stop IN number
,in_reference IN varchar2
,in_hdrpassthruchar01 IN varchar2
,in_hdrpassthruchar02 IN varchar2
,in_hdrpassthruchar03 IN varchar2
,in_hdrpassthruchar04 IN varchar2
,in_hdrpassthruchar05 IN varchar2
,in_hdrpassthruchar06 IN varchar2
,in_hdrpassthruchar07 IN varchar2
,in_hdrpassthruchar08 IN varchar2
,in_hdrpassthruchar09 IN varchar2
,in_hdrpassthruchar10 IN varchar2
,in_hdrpassthruchar11 IN varchar2
,in_hdrpassthruchar12 IN varchar2
,in_hdrpassthruchar13 IN varchar2
,in_hdrpassthruchar14 IN varchar2
,in_hdrpassthruchar15 IN varchar2
,in_hdrpassthruchar16 IN varchar2
,in_hdrpassthruchar17 IN varchar2
,in_hdrpassthruchar18 IN varchar2
,in_hdrpassthruchar19 IN varchar2
,in_hdrpassthruchar20 IN varchar2
,in_hdrpassthruchar21 IN varchar2
,in_hdrpassthruchar22 IN varchar2
,in_hdrpassthruchar23 IN varchar2
,in_hdrpassthruchar24 IN varchar2
,in_hdrpassthruchar25 IN varchar2
,in_hdrpassthruchar26 IN varchar2
,in_hdrpassthruchar27 IN varchar2
,in_hdrpassthruchar28 IN varchar2
,in_hdrpassthruchar29 IN varchar2
,in_hdrpassthruchar30 IN varchar2
,in_hdrpassthruchar31 IN varchar2
,in_hdrpassthruchar32 IN varchar2
,in_hdrpassthruchar33 IN varchar2
,in_hdrpassthruchar34 IN varchar2
,in_hdrpassthruchar35 IN varchar2
,in_hdrpassthruchar36 IN varchar2
,in_hdrpassthruchar37 IN varchar2
,in_hdrpassthruchar38 IN varchar2
,in_hdrpassthruchar39 IN varchar2
,in_hdrpassthruchar40 IN varchar2
,in_hdrpassthruchar41 IN varchar2
,in_hdrpassthruchar42 IN varchar2
,in_hdrpassthruchar43 IN varchar2
,in_hdrpassthruchar44 IN varchar2
,in_hdrpassthruchar45 IN varchar2
,in_hdrpassthruchar46 IN varchar2
,in_hdrpassthruchar47 IN varchar2
,in_hdrpassthruchar48 IN varchar2
,in_hdrpassthruchar49 IN varchar2
,in_hdrpassthruchar50 IN varchar2
,in_hdrpassthruchar51 IN varchar2
,in_hdrpassthruchar52 IN varchar2
,in_hdrpassthruchar53 IN varchar2
,in_hdrpassthruchar54 IN varchar2
,in_hdrpassthruchar55 IN varchar2
,in_hdrpassthruchar56 IN varchar2
,in_hdrpassthruchar57 IN varchar2
,in_hdrpassthruchar58 IN varchar2
,in_hdrpassthruchar59 IN varchar2
,in_hdrpassthruchar60 IN varchar2
,in_hdrpassthrunum01 IN number
,in_hdrpassthrunum02 IN number
,in_hdrpassthrunum03 IN number
,in_hdrpassthrunum04 IN number
,in_hdrpassthrunum05 IN number
,in_hdrpassthrunum06 IN number
,in_hdrpassthrunum07 IN number
,in_hdrpassthrunum08 IN number
,in_hdrpassthrunum09 IN number
,in_hdrpassthrunum10 IN number
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_importfileid IN varchar2
,in_seq IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2);

procedure end_of_inbound204_import
(in_importfileid IN varchar2
,in_seq IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
);



end zimportproc8;
/
show error package zimportproc8;
exit;
