--
-- $Id$
--
create or replace package alps.rma as


-- Public procedures


procedure get_next_rma(out_rma     out varchar2,
                       out_message out varchar2);

procedure start_rf_return(io_rma          in out varchar2,
                          io_custid       in out varchar2,
                          io_orderid   	in out number,
                          io_shipid    	in out number,
                          out_rma_is_new  out varchar2,
                          out_loadno   	out number,
                          out_stopno   	out number,
                          out_shipno   	out number,
                          out_po       	out varchar2,
                          out_shipper     out varchar2,
                          out_error    	out varchar2,
                          out_message  	out varchar2);

end rma;
/

exit;
