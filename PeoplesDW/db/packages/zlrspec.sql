--
-- $Id: zlicspec.sql 6147 2011-02-17 21:20:49Z ed $
--
create or replace package alps.zlicensereport as

procedure populate_usersessions
   (in_crt	       in number,
    in_legacyrf    in number,
    in_webrf       in number,
    out_msg        out varchar2);
	
procedure populate_fac_usersessions
   (in_facility    in varchar2,
	in_crt	       in number,
    in_legacyrf    in number,
    in_webrf       in number,
    out_msg        out varchar2);
	
end zlicensereport;
/

exit;	