--
-- $Id$
--
create or replace package alps.comments as

procedure order_instruction
(in_orderid in number
,in_shipid in number
,out_comment out long
);

procedure order_bolcomment
(in_orderid in number
,in_shipid in number
,out_comment out long
);

procedure line_instruction
(in_orderid in number
,in_shipid in number
,in_item in varchar2
,in_lotnumber in varchar2
,out_comment out long
);

procedure line_bolcomment
(in_orderid in number
,in_shipid in number
,in_item in varchar2
,in_lotnumber in varchar2
,out_comment out long
);

end comments;
/

exit;
