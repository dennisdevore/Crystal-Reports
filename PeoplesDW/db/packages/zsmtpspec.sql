--
-- $Id$
--
create or replace package alps.simplemailtransferprotocol as

-- constants

MAILER_ID      constant varchar2(256) := 'Oracle UTL_SMTP';
HTML_BOUNDARY  constant varchar2(255) := '------------a1b2c3d4e3f2g1';
HTML_MIME_TYPE constant varchar2(255) := 'multipart/alternative; boundary="'||HTML_BOUNDARY||'"';
HTML_HEADER    constant varchar2(255) := '<html><body>';
HTML_TRAILER   constant varchar2(255) := '</body></html>';


function get_address
   (io_addr_list in out varchar2)
return varchar2;
pragma restrict_references (get_address, wnds);

procedure send_html_email
   (in_sender     in varchar2,
    in_recipients in varchar2,
    in_subject    in varchar2,
    in_text_body  in clob,
    in_html_body  in clob);

procedure mail
   (in_recipients in varchar2,
    in_subject    in varchar2,
    in_message    in varchar2);

procedure email_shipped_order
   (in_orderid in number,
    in_shipid  in number);

procedure notify_order_shipped
   (in_orderid in number,
    in_shipid  in number);

procedure email_closed_load
   (in_loadno  in number);

procedure notify_load_closed
   (in_loadno  in number);

procedure send_mail
   (in_sender     in varchar2,
    in_to         in varchar2,
    in_cc         in varchar2,
    in_bcc        in varchar2,
    in_subject    in varchar2,
    in_msg        in varchar2,
    in_priority   in pls_integer default null);


end simplemailtransferprotocol;
/

exit;
