--
-- $Id$
--
CREATE OR REPLACE PACKAGE   zpallettrack
AS
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
                                ,in_lastuser varchar2);


procedure check_load_complete(
          in_loadno IN number,
          out_errmsg IN OUT varchar2);

FUNCTION calc_cust_begbal(
    in_custid varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number;

FUNCTION calc_cust_endbal(
    in_custid varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number;

FUNCTION calc_carr_begbal(
    in_carrier varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number;

FUNCTION calc_carr_endbal(
    in_carrier varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number;

FUNCTION calc_cons_begbal(
    in_consignee varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number;

FUNCTION calc_cons_endbal(
    in_consignee varchar2,
    in_facility varchar2,
    in_pallettype varchar2,
    in_curdate date
)
RETURN number;

FUNCTION sum_outpallets(
in_loadno number,
in_orderid number,
in_shipid number
)
RETURN integer;

PRAGMA RESTRICT_REFERENCES (calc_cust_begbal, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (calc_cust_endbal, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (calc_carr_begbal, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (calc_carr_endbal, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (calc_cons_begbal, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (calc_cons_endbal, WNDS, WNPS, RNPS);
PRAGMA RESTRICT_REFERENCES (sum_outpallets, WNDS, WNPS, RNPS);

end zpallettrack;
/
