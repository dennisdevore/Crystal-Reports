set define off
create or replace package body alps.simplemailtransferprotocol as
--
-- $Id$
--


-- Types


type emailnotifysubstbltype is table of varchar2(32767) index by varchar2(255);


-- Private procedures


procedure write_mime_header
   (io_conn  in out nocopy utl_smtp.connection,
    in_name  in varchar2,
    in_value in varchar2)
is
begin
   utl_smtp.write_data(io_conn, in_name || ': ' || in_value || utl_tcp.crlf);
end write_mime_header;


procedure write_text
   (io_conn    in out nocopy utl_smtp.connection,
    in_message in varchar2)
is
begin
   utl_smtp.write_data(io_conn, in_message);
end write_text;


-- Private functions

function clean_pass(l_pass in varchar2)
return varchar2
is
  l_var varchar2(256);
begin
  l_var := l_pass;
  l_var := replace(l_var, Chr(13), '');
  l_var := replace(l_var, Chr(10), '');
  return l_var;
end;
function begin_mail
   (in_sender     in varchar2,
    in_recipients in varchar2,
    in_subject    in varchar2,
    in_mime_type  in varchar2    default 'text/plain; charset=us-ascii',
    in_priority   in pls_integer default null)
return utl_smtp.connection
is
   l_conn utl_smtp.connection;
   l_user varchar2(256) := zci.default_value('SMTP_USER');
   l_pass varchar2(256) := zci.default_value('SMTP_PASS');
   l_recipients varchar2(32767) := in_recipients;
   l_sender varchar2(32767) := in_sender;
begin
   -- open SMTP connection
   l_conn := utl_smtp.open_connection(zci.default_value('SMTP_HOST'), zci.default_value('SMTP_PORT'));
   utl_smtp.ehlo(l_conn, zci.default_value('SMTP_DOMAIN'));

   -- perform authentication (if required)
   if (l_user is not null) and (l_pass is not null) then
      l_pass := clean_pass(utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(l_pass))));
      utl_smtp.command(l_conn, 'AUTH LOGIN');
      utl_smtp.command(l_conn,
            utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(l_user))));
      utl_smtp.command(l_conn, l_pass);
   end if;

   -- Specify sender's address
   utl_smtp.mail(l_conn, get_address(l_sender));

   -- Specify recipient(s) of the email.
   while (l_recipients is not null) loop
      utl_smtp.rcpt(l_conn, get_address(l_recipients));
   end loop;

   -- Start body of email
   utl_smtp.open_data(l_conn);
   write_mime_header(l_conn, 'MIME-Version', '1.0');

   -- Set "From" MIME header
   write_mime_header(l_conn, 'From', in_sender);

   -- Set "To" MIME header
   write_mime_header(l_conn, 'To', in_recipients);

   -- Set "Date" MIME header
   write_mime_header(l_conn, 'Date', to_char(sysdate, 'dd Mon yy hh24:mi:ss'));

   -- Set "Subject" MIME header
   write_mime_header(l_conn, 'Subject', in_subject);

   -- Set "Content-Type" MIME header
   write_mime_header(l_conn, 'Content-Type', in_mime_type);

   -- Set "X-Mailer" MIME header
   write_mime_header(l_conn, 'X-Mailer', nvl(zci.default_value('SMTP_MAILER_ID'), MAILER_ID));

   -- Set priority:
   if (in_priority is not null) then
      write_mime_header(l_conn, 'X-Priority', in_priority);
   end if;

   -- Send an empty line to denote end of MIME headers and beginning of message body.
   utl_smtp.write_data(l_conn, utl_tcp.crlf);

   if (in_mime_type like 'multipart/%') then
      write_text(l_conn, 'This is a multi-part message in MIME format.' || utl_tcp.crlf);
   end if;

   return l_conn;
end begin_mail;


-- Public functions


-- Return the next email address in the list of email addresses, separated
-- by either a "," or a ";".  The format of mailbox may be in one of these:
--   someone@some-domain
--   "Someone at some domain" <someone@some-domain>
--   Someone at some domain <someone@some-domain>
function get_address
   (io_addr_list in out varchar2)
return varchar2
is
   addr varchar2(256);
   i pls_integer;

   function lookup_unquoted_char
      (in_str  in varchar2,
       in_chrs in varchar2)
   return pls_integer
   as
      c varchar2(5);
      i pls_integer := 1;
      len pls_integer := length(in_str);
      inside_quote boolean := false;
   begin
      while (i <= len) loop
         c := substr(in_str, i, 1);
         if (inside_quote) then
            if (c = '"') then
               inside_quote := false;
            elsif (c = '\') then
               i := i + 1; -- Skip the quote character
            end if;
            goto next_char;
         end if;

         if (c = '"') then
            inside_quote := true;
            goto next_char;
         end if;

         if (instr(in_chrs, c) >= 1) then
            return i;
         end if;

<<next_char>>
         i := i + 1;

      end loop;

      return 0;
   end;

begin

   io_addr_list := ltrim(io_addr_list);
   i := lookup_unquoted_char(io_addr_list, ',;');
   if (i >= 1) then
      addr := substr(io_addr_list, 1, i - 1);
      io_addr_list := substr(io_addr_list, i + 1);
   else
      addr := io_addr_list;
      io_addr_list := '';
   end if;

   if nvl(zci.default_value('SMTP_BRACKET_ADDR'),'N') = 'Y' then
      if substr(addr, 1, 1) != '<' then
         addr := '<' || addr;
      end if;
      if substr(addr, -1 ,1) != '>' then
         addr := addr || '>';
      end if;
   else
      i := lookup_unquoted_char(addr, '<');
      if (i >= 1) then
         addr := substr(addr, i + 1);
         i := instr(addr, '>');
         if (i >= 1) then
            addr := substr(addr, 1, i - 1);
         end if;
      end if;
   end if;

   return addr;
end get_address;


-- Public procedures


procedure send_html_email
   (in_sender     in varchar2,
    in_recipients in varchar2,
    in_subject    in varchar2,
    in_text_body  in clob,
    in_html_body  in clob)
is
   l_conn utl_smtp.connection;

   procedure print_body
      (io_conn in out nocopy utl_smtp.connection,
       in_body in clob)
   is
      l_offset pls_integer := 1;
      l_amount pls_integer := 1900;
   begin

      while l_offset < dbms_lob.getlength(in_body) loop
         write_text(io_conn, dbms_lob.substr(in_body, l_amount, l_offset));
         l_offset := l_offset + l_amount ;
         l_amount := least(1900, dbms_lob.getlength(in_body) - l_amount);
      end loop;
   end print_body;
begin
   l_conn := begin_mail(in_sender, in_recipients, in_subject, HTML_MIME_TYPE);

   -- Write the text boundary and text body
   write_text(l_conn, '--' || HTML_BOUNDARY || utl_tcp.crlf);
   write_mime_header(l_conn, 'Content-Type', 'text/plain; charset=us-ascii' || utl_tcp.crlf);
   print_body(l_conn, in_text_body);

   -- Write the html boundary and html body
   write_text(l_conn, utl_tcp.crlf||utl_tcp.crlf||'--' || HTML_BOUNDARY || utl_tcp.crlf);
   write_mime_header(l_conn, 'Content-Type', 'text/html;' || utl_tcp.crlf);
   print_body(l_conn, in_html_body);

   -- Write the final html boundary
   write_text(l_conn, utl_tcp.crlf || '--' ||  HTML_BOUNDARY || '--' || chr(13));

   utl_smtp.close_data(l_conn);
   utl_smtp.quit(l_conn);
   utl_tcp.close_all_connections;

exception
   when OTHERS then
      utl_smtp.quit(l_conn);
	  utl_tcp.close_all_connections;
      raise;                     -- re-raise the exception for the caller
end send_html_email;


procedure mail
   (in_recipients in varchar2,
    in_subject    in varchar2,
    in_message    in varchar2)
is
   l_msg varchar2(32767);
   l_conn utl_smtp.connection;
begin
   l_conn := begin_mail(nvl(zci.default_value('SMTP_SENDER'),
         'synapse@'||zci.default_value('SMTP_DOMAIN')), in_recipients, in_subject);
   write_text(l_conn, in_message);
   utl_smtp.close_data(l_conn);
   utl_smtp.quit(l_conn);
   zms.log_autonomous_msg('Mail', null, null,
         'Email sent to '||in_recipients||' about: '||in_subject,
          'I', null, l_msg);
exception
   when OTHERS then
      utl_smtp.quit(l_conn);
      zms.log_autonomous_msg('Mail', null, null, sqlerrm, 'E', null, l_msg);
end mail;


procedure email_shipped_order
   (in_orderid in number,
    in_shipid  in number)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select OH.custid as custid,
             OH.fromfacility as fromfacility,
             nvl(OH.shiptype,'L') as shiptype,
             OH.reference as reference,
             OH.po as po,
             OH.billoflading as bol,
             decode(OH.shiptoname, null, CN.name, OH.shiptoname) as shiptoname,
             decode(OH.shiptoname, null, CN.addr1, OH.shiptoaddr1) as shiptoaddr1,
             decode(OH.shiptoname, null, CN.addr2, OH.shiptoaddr2) as shiptoaddr2,
             decode(OH.shiptoname, null, CN.city, OH.shiptocity) as shiptocity,
             decode(OH.shiptoname, null, CN.state, OH.shiptostate) as shiptostate,
             decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode) as shiptopostalcode,
             nvl(CA.name, OH.carrier) as carrier,
             CA.trackerurl as trackerurl,
             OH.deliveryservice as deliveryservice,
             OH.dateshipped as dateshipped,
             OH.prono as pronumber,
             LD.prono as loadpronumber,
             LD.trailer as loadtrailer,
             LD.seal as loadseal,
             LD.billoflading as loadbol,
             decode(OH.shiptoname, null, CN.email, OH.shiptoemail) as toaddr,
             OH.hdrpassthruchar01 as hdrpassthruchar01,
             OH.hdrpassthruchar02 as hdrpassthruchar02,
             OH.hdrpassthruchar03 as hdrpassthruchar03,
             OH.hdrpassthruchar04 as hdrpassthruchar04,
             OH.hdrpassthruchar05 as hdrpassthruchar05,
             OH.hdrpassthruchar06 as hdrpassthruchar06,
             OH.hdrpassthruchar07 as hdrpassthruchar07,
             OH.hdrpassthruchar08 as hdrpassthruchar08,
             OH.hdrpassthruchar09 as hdrpassthruchar09,
             OH.hdrpassthruchar10 as hdrpassthruchar10,
             OH.hdrpassthruchar11 as hdrpassthruchar11,
             OH.hdrpassthruchar12 as hdrpassthruchar12,
             OH.hdrpassthruchar13 as hdrpassthruchar13,
             OH.hdrpassthruchar14 as hdrpassthruchar14,
             OH.hdrpassthruchar15 as hdrpassthruchar15,
             OH.hdrpassthruchar16 as hdrpassthruchar16,
             OH.hdrpassthruchar17 as hdrpassthruchar17,
             OH.hdrpassthruchar18 as hdrpassthruchar18,
             OH.hdrpassthruchar19 as hdrpassthruchar19,
             OH.hdrpassthruchar20 as hdrpassthruchar20,
             OH.hdrpassthrunum01 as hdrpassthrunum01,
             OH.hdrpassthrunum02 as hdrpassthrunum02,
             OH.hdrpassthrunum03 as hdrpassthrunum03,
             OH.hdrpassthrunum04 as hdrpassthrunum04,
             OH.hdrpassthrunum05 as hdrpassthrunum05,
             OH.hdrpassthrunum06 as hdrpassthrunum06,
             OH.hdrpassthrunum07 as hdrpassthrunum07,
             OH.hdrpassthrunum08 as hdrpassthrunum08,
             OH.hdrpassthrunum09 as hdrpassthrunum09,
             OH.hdrpassthrunum10 as hdrpassthrunum10,
             OH.hdrpassthrudate01 as hdrpassthrudate01,
             OH.hdrpassthrudate02 as hdrpassthrudate02,
             OH.hdrpassthrudate03 as hdrpassthrudate03,
             OH.hdrpassthrudate04 as hdrpassthrudate04,
             OH.hdrpassthrudoll01 as hdrpassthrudoll01,
             OH.hdrpassthrudoll02 as hdrpassthrudoll02
         from orderhdr OH, consignee CN, carrier CA, loads LD
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and CN.consignee (+) = OH.shipto
           and CA.carrier (+) = OH.carrier
           and LD.loadno (+) = OH.loadno;
   oh c_oh%rowtype := null;
   cursor c_cus(p_custid varchar2, p_shiptype varchar2) is
      select nvl(decode(p_shiptype, 'S', sendsmallpkgemail,
                                         sendnonsmallpkgemail),'N') as sendemail,
             decode(p_shiptype, 'S', smallpkgfrom,
                                     nonsmallpkgfrom) as fromaddr
         from customer
         where custid = p_custid;
   cus c_cus%rowtype := null;
   l_msg varchar2(32767);
   l_found boolean;
   l_body_raw clob := empty_clob;
   l_body_fmt clob := empty_clob;
   l_body_html clob := empty_clob;
   l_beg pls_integer;
   l_end pls_integer;
   l_last pls_integer;
   l_orderdetail_needed boolean := true;
   l_trackingnos_needed boolean := true;
   emsubs emailnotifysubstbltype;

   l_multishipcost  varchar2(10);

   procedure init_emsubs
   is
   begin
      emsubs.delete;

      emsubs('%ORDER%') := in_orderid||'-'||in_shipid;
      emsubs('%REFERENCE%') := oh.reference;
      emsubs('%PO%') := oh.po;
      emsubs('%BOL%') := oh.bol;
      emsubs('%SHIPTONAME%') := oh.shiptoname;
      emsubs('%SHIPTOADDR1%') := oh.shiptoaddr1;
      emsubs('%SHIPTOADDR2%') := oh.shiptoaddr2;
      emsubs('%SHIPTOCITY%') := oh.shiptocity;
      emsubs('%SHIPTOSTATE%') := oh.shiptostate;
      emsubs('%SHIPTOPOSTALCODE%') := oh.shiptopostalcode;
      emsubs('%CARRIER%') := oh.carrier;
      emsubs('%DELIVERYSERVICE%') := oh.deliveryservice;
      emsubs('%DATESHIPPED%') := oh.dateshipped;
      emsubs('%PRONUMBER%') := oh.pronumber;
      emsubs('%LOADPRONUMBER%') := oh.loadpronumber;
      emsubs('%LOADTRAILER%') := oh.loadtrailer;
      emsubs('%LOADSEAL%') := oh.loadseal;
      emsubs('%LOADBOL%') := oh.loadbol;
      emsubs('%HDRPASSTHRUCHAR01%') := oh.hdrpassthruchar01;
      emsubs('%HDRPASSTHRUCHAR02%') := oh.hdrpassthruchar02;
      emsubs('%HDRPASSTHRUCHAR03%') := oh.hdrpassthruchar03;
      emsubs('%HDRPASSTHRUCHAR04%') := oh.hdrpassthruchar04;
      emsubs('%HDRPASSTHRUCHAR05%') := oh.hdrpassthruchar05;
      emsubs('%HDRPASSTHRUCHAR06%') := oh.hdrpassthruchar06;
      emsubs('%HDRPASSTHRUCHAR07%') := oh.hdrpassthruchar07;
      emsubs('%HDRPASSTHRUCHAR08%') := oh.hdrpassthruchar08;
      emsubs('%HDRPASSTHRUCHAR09%') := oh.hdrpassthruchar09;
      emsubs('%HDRPASSTHRUCHAR10%') := oh.hdrpassthruchar10;
      emsubs('%HDRPASSTHRUCHAR11%') := oh.hdrpassthruchar11;
      emsubs('%HDRPASSTHRUCHAR12%') := oh.hdrpassthruchar12;
      emsubs('%HDRPASSTHRUCHAR13%') := oh.hdrpassthruchar13;
      emsubs('%HDRPASSTHRUCHAR14%') := oh.hdrpassthruchar14;
      emsubs('%HDRPASSTHRUCHAR15%') := oh.hdrpassthruchar15;
      emsubs('%HDRPASSTHRUCHAR16%') := oh.hdrpassthruchar16;
      emsubs('%HDRPASSTHRUCHAR17%') := oh.hdrpassthruchar17;
      emsubs('%HDRPASSTHRUCHAR18%') := oh.hdrpassthruchar18;
      emsubs('%HDRPASSTHRUCHAR19%') := oh.hdrpassthruchar19;
      emsubs('%HDRPASSTHRUCHAR20%') := oh.hdrpassthruchar20;
      emsubs('%HDRPASSTHRUNUM01%') := oh.hdrpassthrunum01;
      emsubs('%HDRPASSTHRUNUM02%') := oh.hdrpassthrunum02;
      emsubs('%HDRPASSTHRUNUM03%') := oh.hdrpassthrunum03;
      emsubs('%HDRPASSTHRUNUM04%') := oh.hdrpassthrunum04;
      emsubs('%HDRPASSTHRUNUM05%') := oh.hdrpassthrunum05;
      emsubs('%HDRPASSTHRUNUM06%') := oh.hdrpassthrunum06;
      emsubs('%HDRPASSTHRUNUM07%') := oh.hdrpassthrunum07;
      emsubs('%HDRPASSTHRUNUM08%') := oh.hdrpassthrunum08;
      emsubs('%HDRPASSTHRUNUM09%') := oh.hdrpassthrunum09;
      emsubs('%HDRPASSTHRUNUM10%') := oh.hdrpassthrunum10;
      emsubs('%HDRPASSTHRUDATE01%') := oh.hdrpassthrudate01;
      emsubs('%HDRPASSTHRUDATE02%') := oh.hdrpassthrudate02;
      emsubs('%HDRPASSTHRUDATE03%') := oh.hdrpassthrudate03;
      emsubs('%HDRPASSTHRUDATE04%') := oh.hdrpassthrudate04;
      emsubs('%HDRPASSTHRUDOLL01%') := oh.hdrpassthrudoll01;
      emsubs('%HDRPASSTHRUDOLL02%') := oh.hdrpassthrudoll02;
      emsubs('%MULTISHIPCOST%') := l_multishipcost;

   end init_emsubs;

   procedure copy_raw
      (in_start in number,
       in_end   in number)
   is
      l_start pls_integer := in_start;
      l_len pls_integer;
      l_remain pls_integer := in_end-in_start+1;
      l_raw varchar2(32767);
      l_buff varchar2(32767);
   begin
      loop
         l_len := least(l_remain, 255);
         exit when (l_len <= 0);
         dbms_lob.read(l_body_raw, l_len, l_start, l_raw);
         dbms_lob.write(l_body_fmt, l_len, dbms_lob.getlength(l_body_fmt)+1, l_raw);
         l_buff := replace(l_raw, utl_tcp.crlf, '<br>');
         dbms_lob.write(l_body_html, length(l_buff), dbms_lob.getlength(l_body_html)+1, l_buff);
         l_start := l_start+l_len;
         l_remain := l_remain-l_len;
      end loop;
   end copy_raw;

   procedure copy_orderdetail
      (in_force boolean)
   is
      l_buff varchar2(32767);
   begin
      if l_orderdetail_needed or in_force then
         l_buff := utl_tcp.crlf||utl_tcp.crlf||'Detail:'||utl_tcp.crlf||utl_tcp.crlf;
         dbms_lob.write(l_body_fmt, length(l_buff), dbms_lob.getlength(l_body_fmt)+1, l_buff);
         l_buff := '<br><br><table border cellspacing=0 cellpadding=5>'
               || '<tr><th colspan=4>Order Detail</th></tr>'
               || '<tr><th>Item</th><th>Description</th><th>Qty</th><th>UOM</th>';
         dbms_lob.write(l_body_html, length(l_buff), dbms_lob.getlength(l_body_html)+1, l_buff);

         for od in (select OD.item as item,
                           CI.descr as descr,
                           sum(OD.qtyship) as qtyship,
                           OD.uom as uom
                     from orderdtl OD, custitem CI
                     where OD.orderid = in_orderid
                       and OD.shipid = in_shipid
                       and nvl(OD.qtyship,0) > 0
                       and CI.custid (+) = OD.custid
                       and CI.item (+) = OD.item
                     group by OD.uom, OD.item, CI.descr
                     order by OD.item) loop

            l_buff := rpad(od.item||' - '||od.descr,60)||lpad(od.qtyship||' '
                  ||rpad(od.uom,4),15)||utl_tcp.crlf;
            dbms_lob.write(l_body_fmt, length(l_buff), dbms_lob.getlength(l_body_fmt)+1, l_buff);
            l_buff := '<tr><td>'||od.item||'</td><td>'||od.descr||'</td><td align="right">'
                  ||od.qtyship ||'</td><td>'||od.uom||'</td></tr>';
            dbms_lob.write(l_body_html, length(l_buff), dbms_lob.getlength(l_body_html)+1, l_buff);
         end loop;
      end if;

      l_buff := '</table>';
      dbms_lob.write(l_body_html, length(l_buff), dbms_lob.getlength(l_body_html)+1, l_buff);

      l_orderdetail_needed := false;
   end copy_orderdetail;

   procedure copy_trackingnos
      (in_force boolean)
   is
      l_buff varchar2(32767);
   begin
      if (l_trackingnos_needed or in_force) and oh.shiptype = 'S' then
         l_buff := utl_tcp.crlf||utl_tcp.crlf||'Tracking Number(s):'||utl_tcp.crlf||utl_tcp.crlf;
         dbms_lob.write(l_body_fmt, length(l_buff), dbms_lob.getlength(l_body_fmt)+1, l_buff);
         l_buff := '<br><b>Tracking Number(s):</b><br>';
         dbms_lob.write(l_body_html, length(l_buff), dbms_lob.getlength(l_body_html)+1, l_buff);

         for md in (select trackid from multishipdtl
                     where orderid = in_orderid
                       and shipid = in_shipid
                     order by trackid) loop

            l_buff := md.trackid||utl_tcp.crlf;
            dbms_lob.write(l_body_fmt, length(l_buff), dbms_lob.getlength(l_body_fmt)+1, l_buff);

            if oh.trackerurl is null then
               l_buff := '&nbsp;&nbsp;'||md.trackid||'<br>';
            else
               l_buff := '&nbsp;&nbsp;<a href="'||substr(oh.trackerurl, 1, instr(oh.trackerurl,'{')-1)
                     ||md.trackid||substr(oh.trackerurl,instr(oh.trackerurl,'}')+1)
                     ||'">'||md.trackid||'</a><br>';
            end if;
            dbms_lob.write(l_body_html, length(l_buff), dbms_lob.getlength(l_body_html)+1, l_buff);
         end loop;
      end if;

      l_trackingnos_needed := false;
   end copy_trackingnos;

   function copy_key
      (in_start in number,
       in_end   in number)
   return boolean
   is
      l_len pls_integer := in_end-in_start+1;
      l_raw varchar2(32767);
      l_buff varchar2(32767);
      l_match boolean := false;
   begin
      dbms_lob.read(l_body_raw, l_len, in_start, l_raw);

      if l_raw = '%ORDERDETAIL%' then
         copy_orderdetail(true);
         return true;
      end if;

      if l_raw = '%TRACKINGNOS%' then
         copy_trackingnos(true);
         return true;
      end if;

      if emsubs.exists(l_raw) then
         if emsubs(l_raw) is not null then
            dbms_lob.write(l_body_fmt, length(emsubs(l_raw)), dbms_lob.getlength(l_body_fmt)+1,
                  emsubs(l_raw));
            dbms_lob.write(l_body_html, length(emsubs(l_raw)), dbms_lob.getlength(l_body_html)+1,
                  emsubs(l_raw));
         end if;
         l_match := true;
      end if;

--    no match copy all but trailing %
      if not l_match then
         dbms_lob.write(l_body_fmt, l_len-1, dbms_lob.getlength(l_body_fmt)+1, l_raw);
         l_buff := replace(l_raw, utl_tcp.crlf, '<br>');
         dbms_lob.write(l_body_html, length(l_buff)-1, dbms_lob.getlength(l_body_html)+1, l_buff);
      end if;

      return l_match;
   end copy_key;

   procedure print_body
      (io_conn in out nocopy utl_smtp.connection,
       in_body in clob)
   is
      l_offset pls_integer := 1;
      l_amount pls_integer := 1900;
   begin

      while l_offset < dbms_lob.getlength(in_body) loop
         write_text(io_conn, dbms_lob.substr(in_body, l_amount, l_offset));
         l_offset := l_offset + l_amount ;
         l_amount := least(1900, dbms_lob.getlength(in_body) - l_amount);
      end loop;
   end print_body;

begin
   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   l_found := c_oh%found;
   close c_oh;
   if not l_found then
      zms.log_autonomous_msg('NtfyOrdShip', null, null,
            'Order '||in_orderid||'-'||in_shipid||' not found',
            'E', null, l_msg);
      return;
   end if;

   open c_cus(oh.custid, oh.shiptype);
   fetch c_cus into cus;
   l_found := c_cus%found;
   close c_cus;
   if not l_found then
      zms.log_autonomous_msg('NtfyOrdShip', null, oh.custid,
            'Order '||in_orderid||'-'||in_shipid||' customer not found',
            'E', null, l_msg);
      return;
   end if;

   if cus.sendemail != 'Y' then
      return;
   end if;

   if oh.toaddr is null then
      zms.log_autonomous_msg('NtfyOrdShip', null, null,
            'Order '||in_orderid||'-'||in_shipid||' no email to address',
            'E', null, l_msg);
      return;
   end if;

   if cus.fromaddr is null then
      zms.log_autonomous_msg('NtfyOrdShip', null, oh.custid,
            'Order '||in_orderid||'-'||in_shipid||' no from address for type '||oh.shiptype,
            'E', null, l_msg);
      return;
   end if;

   if oh.shiptype = 'S' then
      select smallpkgbody into l_body_raw
         from customer
         where custid = oh.custid;
   else
      select nonsmallpkgbody into l_body_raw
         from customer
         where custid = oh.custid;
   end if;

   dbms_lob.createtemporary(l_body_fmt, false, dbms_lob.call);
   dbms_lob.createtemporary(l_body_html, false, dbms_lob.call);
   dbms_lob.write(l_body_html, length(HTML_HEADER), 1, HTML_HEADER);

   l_multishipcost := '';
   begin
    select to_char(sum(nvl(cost,0)),'FM99990.00')
      into l_multishipcost
      from multishipdtl
     where orderid = in_orderid
       and shipid = in_shipid;
   exception when others then
     l_multishipcost := '';
   end;
   if l_multishipcost is null then
     l_multishipcost := '0.00';
   end if;

   init_emsubs;

   l_last := dbms_lob.getlength(l_body_raw);
   if l_last > 0 then
      l_beg := dbms_lob.instr(l_body_raw, '%');
      if l_beg = 0 then
         copy_raw(1, l_last);
      else
         copy_raw(1, l_beg-1);
         loop
            l_end := dbms_lob.instr(l_body_raw, '%', l_beg+1);
            if l_end = 0 then
               copy_raw(l_beg, l_last);
               exit;
            end if;

            if copy_key(l_beg, l_end) then
               l_beg := dbms_lob.instr(l_body_raw, '%', l_end+1);
               if l_beg = 0 then
                  copy_raw(l_end+1, l_last);
                  exit;
               else
                  copy_raw(l_end+1, l_beg-1);
               end if;
            else
               l_beg := l_end;
            end if;
         end loop;
      end if;
   end if;

   copy_orderdetail(false);
   copy_trackingnos(false);
   dbms_lob.write(l_body_html, length(HTML_TRAILER), dbms_lob.getlength(l_body_html)+1,
         HTML_TRAILER);

   send_html_email(cus.fromaddr, oh.toaddr,
         'Order Ship Confirmation (Order #'||emsubs('%ORDER%')||')',
         l_body_fmt, l_body_html);

   zms.log_autonomous_msg('NtfyOrdShip', oh.fromfacility, oh.custid,
         'Email sent for order '||in_orderid||'-'||in_shipid||' to: '||oh.toaddr,
          'I', null, l_msg);

   dbms_lob.freetemporary(l_body_fmt);
   dbms_lob.freetemporary(l_body_html);

exception
   when OTHERS then
      zms.log_autonomous_msg('NtfyOrdShip', oh.fromfacility, oh.custid,
            sqlerrm || ' order = ' || in_orderid || '-' || in_shipid
            || ' from = ' || cus.fromaddr || ' to = ' || oh.toaddr,
            'E', null, l_msg);
end email_shipped_order;


procedure notify_order_shipped
   (in_orderid in number,
    in_shipid  in number)
is
   l_status integer;
   l_msg varchar2(32767);
   l_qmsg qmsg := qmsg('SEND', lpad(in_orderid,9,'0')||lpad(in_shipid,2,'0'));
begin

   l_status := zqm.send('email_in', l_qmsg.trans, l_qmsg.message, 1, null);

exception
   when OTHERS then
      zms.log_autonomous_msg('NtfyOrdShip', null, null, sqlerrm, 'E', null, l_msg);
end notify_order_shipped;


procedure email_closed_load
   (in_loadno in number)
is
   cursor c_load(p_loadno number) is
      select ca.carrier,
             ca.name carriername,
             ca.NOTIFYONRECEIPTCLOSE,
             ca.NOTIFYONRECEIPTCLOSEBODY,
             ca.NOTIFYONRECEIPTCLOSEFROM,
             ca.NOTIFYONRECEIPTCLOSETO,
             ca.NOTIFYONSHIPCLOSE,
             ca.NOTIFYONSHIPCLOSEBODY,
             ca.NOTIFYONSHIPCLOSEFROM,
             ca.NOTIFYONSHIPCLOSETO,
             ld.trailer loadtrailer,
             ld.loadno,
             ld.billoflading loadbol,
             ld.seal loadseal,
             ld.prono loadpronumber,
             ld.loadtype,
             to_char(ld.statusupdate,'dd-mon-yyyy') closedate,
             to_char(ld.statusupdate,'hh24:mi') closetime
        from carrier CA, loads LD
       where CA.carrier (+) = LD.carrier
         and LD.loadno (+) = p_loadno;
   load c_load%rowtype := null;
   cursor c_orderhdr(p_loadno number) is
      select orderid, reference, po
        from orderhdr
       where loadno = p_loadno;
   cursor c_cust(p_loadno number) is
      select c.custid,
             c.NOTIFYONRECEIPTCLOSE,
             c.NOTIFYONRECEIPTCLOSEBODY,
             c.NOTIFYONRECEIPTCLOSEFROM,
             c.NOTIFYONRECEIPTCLOSETO,
             c.NOTIFYONSHIPCLOSE,
             c.NOTIFYONSHIPCLOSEBODY,
             c.NOTIFYONSHIPCLOSEFROM,
             c.NOTIFYONSHIPCLOSETO
        from (select distinct custid from orderhdr where loadno = p_loadno) oh, customer c
       where oh.custid = c.custid;
   cursor c_custorders(p_loadno number,p_custid varchar2) is
      select orderid, reference, po
        from orderhdr
       where loadno = p_loadno
         and custid = p_custid;
   l_msg varchar2(32767);
   l_found boolean;
   l_conn utl_smtp.connection;
   l_body clob;
   l_beg pls_integer;
   l_end pls_integer;
   l_last pls_integer;
   l_orderid   varchar2(4000);
   l_reference varchar2(4000);
   l_po        varchar2(4000);
   l_send_load_email boolean;
   l_send_cust_email boolean;
   l_email_to_address varchar2(32767);
   l_email_from_address varchar2(32767);

   -- structure to hold the wildcards and their substitution strings
   type emailnotifysubsrectype is record (
     key varchar2(32),
     value varchar2(255));
   type emailnotifysubstbltype is table of emailnotifysubsrectype index by binary_integer;
   emsubs emailnotifysubstbltype;

   -- writes portion of body of email out to smtp connection
   procedure print_body
      (io_conn  in out nocopy utl_smtp.connection,
       in_start in number,
       in_end   in number)
   is
      l_start pls_integer := in_start;
      l_len pls_integer;
      l_remain pls_integer := in_end-in_start+1;
      l_buff varchar2(255);
   begin
      loop
         l_len := least(l_remain, 255);
         exit when (l_len <= 0);
         dbms_lob.read(l_body, l_len, l_start, l_buff);
         write_text(io_conn, l_buff);
         exit when (l_len >= l_remain) or (l_remain <= 0);
         l_start := l_start+l_len;
         l_remain := l_remain-l_len;
      end loop;
   end print_body;

   -- find wildcard match in emsubs array and write string
   -- out to smtp connection
   function key_printed
      (io_conn  in out nocopy utl_smtp.connection,
       in_start in number,
       in_end   in number)
   return boolean
   is
      i binary_integer;
      l_len pls_integer := in_end-in_start+1;
      l_buff varchar2(255);
      l_match boolean := false;
   begin
      if l_len <= 32 then
         dbms_lob.read(l_body, l_len, in_start, l_buff);
         for i in 1..emsubs.count loop
            if emsubs(i).key = l_buff then
               if emsubs(i).value is not null then
                  write_text(io_conn, emsubs(i).value);
               end if;
               l_match := true;
               exit;
            end if;
         end loop;
      end if;

      if not l_match then
         write_text(io_conn, l_buff);
      end if;

      return l_match;
   end key_printed;

   -- runs through body of email replacing wildcards using the key_printed function
   -- and writes the body out to the email using the print_body procedure.
   procedure print_email
      (io_conn  in out nocopy utl_smtp.connection) is
      l_beg pls_integer;
      l_end pls_integer;
      l_last pls_integer;
   begin
   l_last := dbms_lob.getlength(l_body);
   if l_last > 0 then
      l_beg := dbms_lob.instr(l_body, '%');
      if l_beg = 0 then
         print_body(l_conn, 1, l_last);
      else
         print_body(l_conn, 1, l_beg-1);
         loop
            l_end := dbms_lob.instr(l_body, '%', l_beg+1);
            if l_end = 0 then
               print_body(l_conn, l_beg, l_last);
               exit;
            end if;

            if key_printed(l_conn, l_beg, l_end) then
               l_beg := dbms_lob.instr(l_body, '%', l_end+1);
               if l_beg = 0 then
                  print_body(l_conn, l_end+1, l_last);
                  exit;
               else
                  print_body(l_conn, l_end+1, l_beg-1);
               end if;
            else
               l_beg := l_end;
            end if;
         end loop;
      end if;
   end if;
   end print_email;

   function append_string(instring varchar2, addstring varchar2, delimiter varchar2) return varchar2
   is
   begin
     if instring is null then
       return addstring;
     else
       return instring || delimiter || addstring;
     end if;
   end;

begin
   -- get load record and store in load variable.
   open c_load(in_loadno);
   fetch c_load into load;
   l_found := c_load%found;
   close c_load;
   if not l_found then
      zms.log_autonomous_msg('NtfyLdClosed', null, null,
            'Load '||in_loadno||' not found',
            'E', null, l_msg);
      return;
   end if;

   -- initialize emsubs table
   emsubs.delete;

   emsubs(1).key := '%CARRIER%';
   emsubs(1).value := load.carrier;

   emsubs(2).key := '%CARRIERNAME%';
   emsubs(2).value := load.carriername;

   emsubs(3).key := '%LOADTRAILER%';
   emsubs(3).value := load.loadtrailer;

   emsubs(4).key := '%LOADNO%';
   emsubs(4).value := load.loadno;

   emsubs(5).key := '%LOADBOL%';
   emsubs(5).value := load.loadbol;

   emsubs(6).key := '%LOADSEAL%';
   emsubs(6).value := load.loadseal;

   emsubs(7).key := '%LOADPRONUMBER%';
   emsubs(7).value := load.loadpronumber;

   emsubs(8).key := '%CLOSEDDATE%';
   emsubs(8).value := load.closedate;

   emsubs(9).key := '%CLOSEDTIME%';
   emsubs(9).value := load.closetime;

   for oh in c_orderhdr(in_loadno) loop
     l_orderid := append_string(l_orderid,oh.orderid,',');
     l_reference := append_string(l_reference,oh.reference,',');
     l_po := append_string(l_po,oh.po,',');
   end loop;

   emsubs(10).key := '%ORDER%';
   emsubs(10).value := l_orderid;

   emsubs(11).key := '%REFERENCE%';
   emsubs(11).value := l_reference;

   emsubs(12).key := '%PO%';
   emsubs(12).value := l_po;

   l_send_load_email := true;
   case load.loadtype
     when 'INC' then
        if load.notifyonreceiptclose = 'Y' then
           if load.notifyonreceiptcloseto is null then
              zms.log_autonomous_msg('NtfyLdClosed', null, null,
                 'Load '||in_loadno||' no carrier receipt email to address ',
                 'E', null, l_msg);
              l_send_load_email := false;
           end if;
           if load.notifyonreceiptclosefrom is null then
              zms.log_autonomous_msg('NtfyLdClosed', null, null,
                 'Load '||in_loadno||' no carrier receipt email from address ',
                 'E', null, l_msg);
              l_send_load_email := false;
           end if;
           l_body := load.notifyonreceiptclosebody;
           l_email_to_address := load.notifyonreceiptcloseto;
           l_email_from_address := load.notifyonreceiptclosefrom;
        else l_send_load_email := false;
        end if;
     when 'OUTC' then
        if load.notifyonshipclose = 'Y' then
           if load.notifyonshipcloseto is null then
              zms.log_autonomous_msg('NtfyLdClosed', null, null,
                 'Load '||in_loadno||' no carrier ship email to address ',
                 'E', null, l_msg);
              l_send_load_email := false;
           end if;
           if load.notifyonshipclosefrom is null then
              zms.log_autonomous_msg('NtfyLdClosed', null, null,
                 'Load '||in_loadno||' no carrier ship email from address ',
                 'E', null, l_msg);
              l_send_load_email := false;
           end if;
           l_body := load.notifyonshipclosebody;
           l_email_to_address := load.notifyonshipcloseto;
           l_email_from_address := load.notifyonshipclosefrom;
        else l_send_load_email := false;
        end if;
     else l_send_load_email := false;
   end case;

   if l_send_load_email then
      -- send one email to carrier for the load
      l_conn := begin_mail(l_email_from_address, l_email_to_address,
         'Load Close Notification (Load #'||in_loadno||')');

      print_email(l_conn);

      utl_smtp.close_data(l_conn);
      utl_smtp.quit(l_conn);

      zms.log_autonomous_msg('NtfyLdClosed', null, null,
         'Carrier email sent for load '||in_loadno||' to: '||l_email_to_address,
          'I', null, l_msg);
   end if;

   -- send one and only one email for each customer
   -- only orders pertaining to each customer are included in the %ORDER% wildcard
   for cust in c_cust(in_loadno) loop
      l_send_cust_email := true;
      case load.loadtype
        when 'INC' then
           if cust.notifyonreceiptclose = 'Y' then
              if cust.notifyonreceiptcloseto is null then
                 zms.log_autonomous_msg('NtfyLdClosed', null, null,
                    'Load '||in_loadno||' no customer receipt email to address ',
                    'E', null, l_msg);
                 l_send_cust_email := false;
              end if;
              if cust.notifyonreceiptclosefrom is null then
                 zms.log_autonomous_msg('NtfyLdClosed', null, null,
                    'Load '||in_loadno||' no customer receipt email from address ',
                    'E', null, l_msg);
                 l_send_cust_email := false;
              end if;
              l_body := cust.notifyonreceiptclosebody;
              l_email_to_address := cust.notifyonreceiptcloseto;
              l_email_from_address := cust.notifyonreceiptclosefrom;
           else l_send_cust_email := false;
           end if;
        when 'OUTC' then
           if cust.notifyonshipclose = 'Y' then
              if cust.notifyonshipcloseto is null then
                 zms.log_autonomous_msg('NtfyLdClosed', null, null,
                    'Load '||in_loadno||' no customer ship email to address ',
                    'E', null, l_msg);
                 l_send_cust_email := false;
              end if;
              if cust.notifyonshipclosefrom is null then
                 zms.log_autonomous_msg('NtfyLdClosed', null, null,
                    'Load '||in_loadno||' no customer ship email from address ',
                    'E', null, l_msg);
                 l_send_cust_email := false;
              end if;
              l_body := cust.notifyonshipclosebody;
              l_email_to_address := cust.notifyonshipcloseto;
              l_email_from_address := cust.notifyonshipclosefrom;
           else l_send_cust_email := false;
           end if;
        else l_send_cust_email := false;
      end case;

   if l_send_cust_email then

      -- only show orders for the current customer in the email
      l_orderid := null;
      l_reference := null;
      l_po := null;
      for co in c_custorders(in_loadno,cust.custid) loop
        l_orderid := append_string(l_orderid,co.orderid,',');
        l_reference := append_string(l_reference,co.reference,',');
        l_po := append_string(l_po,co.po,',');
      end loop;


      emsubs(10).key := '%ORDER%';
      emsubs(10).value := l_orderid;

      emsubs(11).key := '%REFERENCE%';
      emsubs(11).value := l_reference;

      emsubs(12).key := '%PO%';
      emsubs(12).value := l_po;

      l_conn := begin_mail(l_email_from_address, l_email_to_address,
          'Load Close Notification (Load #'||in_loadno||')');

      print_email(l_conn);

      utl_smtp.close_data(l_conn);
      utl_smtp.quit(l_conn);

      zms.log_autonomous_msg('NtfyLdClosed', null, null,
         'Customer email sent for load '||in_loadno||' customer '||cust.custid|| ' to: '||l_email_to_address,
          'I', null, l_msg);
   end if;
   end loop;

exception
   when OTHERS then
      zms.log_autonomous_msg('NtfyLdClosed', null, null,
            sqlerrm || ' load = ' || in_loadno
            || ' from = ' || l_email_from_address
            || ' to = ' || l_email_to_address,
            'E', null, l_msg);
end email_closed_load;

procedure notify_load_closed
   (in_loadno number)
is
   l_status integer;
   l_msg varchar2(32767);
   l_qmsg qmsg := qmsg('LoadClose', to_char(in_loadno));

begin

   l_status := zqm.send('email_in', l_qmsg.trans, l_qmsg.message, 1, null);

exception
   when OTHERS then
      zms.log_autonomous_msg('NtfyLdClose', null, null, sqlerrm, 'E', null, l_msg);
end notify_load_closed;


procedure send_mail
   (in_sender     in varchar2,
    in_to         in varchar2,
    in_cc         in varchar2,
    in_bcc        in varchar2,
    in_subject    in varchar2,
    in_msg        in varchar2,
    in_priority   in pls_integer default null)
is
   l_conn utl_smtp.connection;
   l_user varchar2(256) := zci.default_value('SMTP_USER');
   l_pass varchar2(256) := zci.default_value('SMTP_PASS');
   l_recipients varchar2(32767);
   l_sender varchar2(32767) := in_sender;
   l_msg varchar(245);
begin
   -- open SMTP connection
   l_conn := utl_smtp.open_connection(zci.default_value('SMTP_HOST'), zci.default_value('SMTP_PORT'));
   utl_smtp.ehlo(l_conn, zci.default_value('SMTP_DOMAIN'));

   -- perform authentication (if required)
   if (l_user is not null) and (l_pass is not null) then
      l_pass := clean_pass(utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(l_pass))));
      utl_smtp.command(l_conn, 'AUTH LOGIN');
      utl_smtp.command(l_conn,
            utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(l_user))));
      utl_smtp.command(l_conn, l_pass);
   end if;

   -- Specify sender's address
   utl_smtp.mail(l_conn, get_address(l_sender));

   -- Specify recipient(s) of the email.
   l_recipients := in_to;
   while (l_recipients is not null) loop
      utl_smtp.rcpt(l_conn, get_address(l_recipients));
   end loop;

   l_recipients := in_cc;
   while (l_recipients is not null) loop
      utl_smtp.rcpt(l_conn, get_address(l_recipients));
   end loop;

   l_recipients := in_bcc;
   while (l_recipients is not null) loop
      utl_smtp.rcpt(l_conn, get_address(l_recipients));
   end loop;

   -- Start body of email
   utl_smtp.open_data(l_conn);
   write_mime_header(l_conn, 'MIME-Version', '1.0');

   -- Set "From" MIME header
   write_mime_header(l_conn, 'From', in_sender);

   -- Set "To" MIME header
   write_mime_header(l_conn, 'To', in_to);

   -- Set "Date" MIME header
   write_mime_header(l_conn, 'Date', to_char(sysdate, 'dd Mon yy hh24:mi:ss'));

   -- Set "CC" MIME header
   write_mime_header(l_conn, 'CC', in_cc);

   -- Set "BCC" MIME header
   write_mime_header(l_conn, 'BCC', in_bcc);

   -- Set "Subject" MIME header
   write_mime_header(l_conn, 'Subject', in_subject);

   -- Set "Content-Type" MIME header
   write_mime_header(l_conn, 'Content-Type', 'text/plain; charset=us-ascii');

   -- Set "X-Mailer" MIME header
   write_mime_header(l_conn, 'X-Mailer', nvl(zci.default_value('SMTP_MAILER_ID'), MAILER_ID));

   -- Set priority:
   if (in_priority is not null) then
      write_mime_header(l_conn, 'X-Priority', in_priority);
   end if;

   -- Send an empty line to denote end of MIME headers and beginning of message body.
   utl_smtp.write_data(l_conn, utl_tcp.crlf);

   write_text(l_conn, in_msg);

   utl_smtp.close_data(l_conn);
   utl_smtp.quit(l_conn);
   utl_tcp.close_all_connections;

   zms.log_autonomous_msg('MAIL', null, null, 
   'SMTP was sent ' || in_subject ||','||
   l_recipients ||','||
   in_to||','||
   in_msg   
   , 'I', null, l_msg);
   return;
exception
   when others then   
	  zms.log_autonomous_msg('MAIL', null, null, sqlerrm || ',' || DBMS_UTILITY.format_error_backtrace, 'E', null, l_msg);
end send_mail;


end simplemailtransferprotocol;
/

show errors package body simplemailtransferprotocol;
exit;
