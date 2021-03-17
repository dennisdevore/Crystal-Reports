create or replace package alps.zmail as

--
-- $Id$
--

-- constants

MAILER_ID   CONSTANT VARCHAR2(256) := 'Oracle UTL_SMTP';

BOUNDARY        CONSTANT VARCHAR2(256) := '-----7D81B75CCC90D2974F7A1CBD';
FIRST_BOUNDARY  CONSTANT VARCHAR2(256) := '--' || BOUNDARY || utl_tcp.crlf;
LAST_BOUNDARY   CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' || utl_tcp.crlf;

procedure send_msg
   (in_recipients in varchar2,
    in_subject    in varchar2,
    in_message    in varchar2,
    in_attachment in varchar2);

end zmail;
/
exit;
