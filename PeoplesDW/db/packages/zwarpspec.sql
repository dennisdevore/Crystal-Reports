--
-- $Id$
--
create or replace package alps.wavereplan
as

PROCEDURE replan_order
   (in_orderid in number,
    in_shipid  in number,
    in_userid in varchar2,
    in_wave in number,
    out_errorno in out number,
    out_msg in out varchar2);

PROCEDURE replan_selected_orders
(in_wave IN number
,in_included_rowids IN clob
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
,out_error_count IN OUT number
);

end wavereplan;
/

exit;
