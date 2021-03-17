--
-- $Id$
--
create or replace package alps.rfxferorder as

procedure receive_lp(in_lpid     in varchar2,
                     in_loadno   in number,
                     in_user     in varchar2,
                     out_error   out varchar2,
                     out_message out varchar2);

end rfxferorder;
/

exit;
