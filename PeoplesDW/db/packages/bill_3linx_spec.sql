--
-- $Id$
--

create or replace package bill_3linx as


function get_weight
   (in_lpid in varchar2,
    in_carton in varchar2,
    in_item in varchar2)
   return number;

function get_cost
   (in_lpid in varchar2,
    in_carton in varchar2,
    in_item in varchar2)
   return number;

function get_insurance
   (in_custid in varchar2,
    in_item in varchar2,
    in_qty in number)
   return number;

function get_insurance2
   (in_custid in varchar2,
    in_item in varchar2,
    in_qty in number,
    in_lpid in varchar2)
   return number;

function get_ordercharge
   (in_lpid in varchar2,
    in_carton in varchar2,
    in_item in varchar2,
    in_orderid in number,
    in_shipid in number)
   return number;

function get_picks
   (in_custid in varchar2,
    in_item in varchar2,
    in_qty in number)
   return number;

function get_picks2
   (in_custid in varchar2,
    in_item in varchar2,
    in_qty in number)
   return integer;

function get_itemcharge
   (in_custid in varchar2,
    in_item in varchar2,
    in_qty in number)
   return number;

function get_surcharge
   (in_lpid in varchar2,
    in_carton in varchar2,
    in_item in varchar2,
    in_orderid in number,
    in_shipid in number,
    in_carrier in varchar2)
   return number;

function get_customdoc
   (in_lpid in varchar2,
    in_carton in varchar2,
    in_item in varchar2,
    in_countrycode in varchar2,
    in_orderid in number,
    in_shipid in number)
   return number;

function get_print
   (in_lpid in varchar2,
    in_carton in varchar2,
    in_item in varchar2,
    in_carrier in varchar2,
    in_orderid in number,
    in_shipid in number)
   return number;


end bill_3linx;
/
show errors package bill_3linx;
exit;
