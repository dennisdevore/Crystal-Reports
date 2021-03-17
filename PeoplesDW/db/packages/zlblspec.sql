--
-- $Id$
--
create or replace package alps.zlabels as


LABEL_DEFAULT_QUEUE      CONSTANT       varchar2(6) := 'LABELS';

function cs_labels
   (in_lpid in varchar2)
return number;
pragma restrict_references (cs_labels, wnds);

function uom_qty_conv
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_qty      in number,
    in_from_uom in varchar2,
    in_to_uom   in varchar2,
    in_floor_yn in varchar2 default null)
return number;
pragma restrict_references (uom_qty_conv, wnds);

function extract_word
   (in_phrase in varchar2,
    in_wordno in number)         -- 1-relative
return varchar2;
pragma restrict_references (extract_word, wnds);

function p1pk_qty_conv
   (in_taskid   in number,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_from_uom in varchar2,
    in_to_uom   in varchar2,
    in_totalize in varchar2)
return number;
pragma restrict_references (p1pk_qty_conv, wnds);

function p1pk_task_carton_count
   (in_taskid   in number)
return number;
pragma restrict_references (p1pk_task_carton_count, wnds);

function p1pk_carton_cnt
   (in_taskid   in number,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_totalize in varchar2)
return number;
pragma restrict_references (p1pk_carton_cnt, wnds);

function caselabel_barcode
   (in_custid in varchar2,
    in_type   in varchar2)
return varchar2;
pragma restrict_references (caselabel_barcode, wnds);

function caselabel_barcode_var_manucc
   (in_custid in varchar2,
    in_type   in varchar2,
    in_manucc in varchar2)
return varchar2;
pragma restrict_references (caselabel_barcode_var_manucc, wnds);

function extract_qualified_data
   (in_phrase    in varchar2,
    in_qualifier in varchar2)
return varchar2;
pragma restrict_references (extract_qualified_data, wnds);

function format_string
   (in_string in varchar2,
    in_format in varchar2)
return varchar2;
pragma restrict_references (format_string, wnds);

function is_lp_unprocessed_autogen
   (in_lpid  in varchar2)
return varchar2;
pragma restrict_references (is_lp_unprocessed_autogen, wnds);

function is_passthru_satisfied
   (in_type          in varchar2,
    in_lpid          in varchar2,
    in_auxdata       in varchar2,
    in_passthrufield in varchar2,
    in_passthruvalue in varchar2)
return varchar2;
pragma restrict_references (is_passthru_satisfied, wnds);

function is_order_satisfied
   (in_orderid        in number,
    in_shipid         in number,
    in_field          in varchar2,
    in_value          in varchar2,
    in_calledfromwave in varchar2 default 'N')
return varchar2;
pragma restrict_references (is_order_satisfied, wnds);

function is_wave_satisfied
   (in_wave  in number,
    in_field in varchar2,
    in_value in varchar2)
return varchar2;
pragma restrict_references (is_wave_satisfied, wnds);

function is_load_satisfied
   (in_loadno in number,
    in_field  in varchar2,
    in_value  in varchar2)
return varchar2;
pragma restrict_references (is_load_satisfied, wnds);

function is_lpid_satisfied
   (in_lpid   in varchar2,
    in_field  in varchar2,
    in_value  in varchar2)
return varchar2;
pragma restrict_references (is_lpid_satisfied, wnds);

function is_bc_satisfied
   (in_barcode in varchar2,
    in_field   in varchar2,
    in_value   in varchar2)
return varchar2;
pragma restrict_references (is_bc_satisfied, wnds);

procedure print_a_plate
   (in_lpid        in varchar2,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    out_message    out varchar2,
    in_action      in varchar2 := 'A');

procedure print_order
   (in_orderid     in number,
    in_shipid      in number,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    out_message    out varchar2);

procedure print_task
   (in_taskid      in number,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    out_message    out varchar2);

procedure p1pk_postprocess
   (in_orderid   in number,
    in_shipid    in number,
    in_custid    in varchar2,
    in_stkno     in varchar2,
    in_seq       in number,
    in_seqof     in number,
    in_barcode   in varchar2,
    in_lpid      in varchar2,
    in_lotnumber in varchar2);

procedure print_a_label
   (in_label_format_path in varchar2,
    in_label_data        in varchar2,
    in_printer           in varchar2,
    in_facility          in varchar2,
    in_copies            in varchar2,
    in_user              in varchar2,
    out_message          out varchar2);

procedure get_plate_profid
   (in_event   in varchar2,
    in_lpid    in varchar2,
    in_type    in varchar2,
    in_action  in varchar2,
    out_uom    out varchar2,
    out_profid out varchar2,
    out_msg    out varchar2);

procedure get_order_profid
   (in_event   in varchar2,
    in_orderid in number,
    in_shipid  in varchar2,
    out_profid out varchar2);

procedure get_task_profid
   (in_event    in varchar2,
    in_taskid   in number,
    out_profid  out varchar2,
    out_orderid out number,
    out_shipid  out number);

procedure print_aiwave_labels
   (in_wave     in varchar2
   ,in_trace    in varchar2
   ,in_printer  in varchar2
   ,in_facility in varchar2
   ,in_user     in varchar2
   ,out_errorno in out number
   ,out_msg     in out varchar2
   );

procedure check_load_arrival_lps
   (in_event    in varchar2,
    in_loadno   in number,
    out_message out varchar2);

procedure print_load_arrival_lps
   (in_event    in varchar2,
    in_loadno   in number,
    in_printer  in varchar2,
    in_user     in varchar2,
    out_message out varchar2);

procedure ld_arrival_lpprt
   (in_orderid in number,
    in_shipid  in number,
    in_item    in varchar2,
    in_uom     in varchar2,
    in_user    in varchar2,
    out_stmt   out varchar2);

procedure is_object_a_view
   (in_obj_name in varchar2,
    out_is_view out varchar2);

procedure print_a_plate_copies
   (in_lpid        in varchar2,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    in_action      in varchar2,
    in_copies      in number,
    in_auxdata     in varchar2,
    out_message    out varchar2);

procedure print_order_copies
   (in_orderid     in number,
    in_shipid      in number,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    in_copies      in number,
    out_message    out varchar2);

procedure print_task_copies
   (in_taskid      in number,
    in_label_rowid in varchar2,
    in_printer     in varchar2,
    in_facility    in varchar2,
    in_user        in varchar2,
    in_copies      in number,
    out_message    out varchar2);

procedure get_plate_profid_aux
   (in_event   in varchar2,
    in_lpid    in varchar2,
    in_type    in varchar2,
    in_action  in varchar2,
    in_auxdata in varchar2,
    out_uom    out varchar2,
    out_profid out varchar2,
    out_msg    out varchar2);

procedure print_aiorder_labels
   (in_profid   in varchar2,
    in_event    in varchar2,
    in_uom      in varchar2,
    in_orderid  in number,
    in_shipid   in number,
    in_printer  in varchar2,
    in_facility in varchar2,
    in_user     in varchar2,
    out_msg     out varchar2);

procedure parse_db_object
   (in_object       in varchar2,
    out_schema      out varchar2,
    out_object_name out varchar2);

procedure any_ai_wave_labels
   (in_wave    in number,
    in_facility in varchar2,
    out_any    out number,
    out_ready  out number);

procedure print_ai_wave_labels
   (in_wave    in number,
    in_printer in varchar2,
    in_user    in varchar2,
    in_facility in varchar2,
    out_msg    out varchar2);

procedure print_lpid
   (in_lpid        in varchar2,
    in_event       in varchar2,
    in_printer     in varchar2,
    in_termid      in varchar2,
    in_userid      in varchar2,
    out_message    out varchar2);

function ohl_combe_sku
   (in_orderid in number,
    in_shipid  in number)
return varchar2;
procedure nicewatch_delimiter
   (out_delimiter out varchar2,
    out_decimal out number);
pragma restrict_references (ohl_combe_sku, wnds);

end zlabels;
/

show errors package zlabels;
exit;
