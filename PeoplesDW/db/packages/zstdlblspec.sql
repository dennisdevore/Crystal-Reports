--
-- $Id: zstdlblspec.sql 753 2007-03-22 21:32:29Z ed $
--
create or replace package zstdlabels as


procedure stdsscc
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

procedure stdcase
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

procedure stdsscc14
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

procedure stdpallet
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure stdsscccntnt
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

procedure stdinnerpack
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

procedure stdinnerpack_nopart
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

procedure stdmultiuom
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

procedure stdpallet_plate
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure stdsscc_plate
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure stdsscc14_plate
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure stdsscccntnt_plate
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure stdinnerpack_plate
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure stdinnerpack_nopart_plate
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure stdpallet_mixeditem
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    out_stmt  out varchar2);

procedure stdsscc_load
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

procedure stdsscc_wave
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

procedure stdsscc14_load
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

procedure stdsscc14_wave
   (in_lpid   in varchar2,       -- Q - query, X - execute
    in_func   in varchar2,       -- A - all, P - print only, C - changes
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

function calc_totalcases
   (in_orderid in number,
    in_shipid  in number)
return ucc_standard_labels.totalcases%type;

function calc_bigseqof
   (in_orderid    in number,
    in_shipid     in number,
    in_shiptype   in varchar2,
    in_cons_order in boolean)
return pls_integer;

function part_of_carton
   (in_type   in varchar2,
    in_parent in varchar2)
return varchar2;

procedure stdreprintbc
   (in_lpid   in varchar2,
    in_func   in varchar2,
    in_action in varchar2,
    in_auxdata in varchar2,
    out_stmt  out varchar2);

end zstdlabels;
/

show error package zstdlabels;
exit;
