create or replace package body alps.zmail as
--
-- $Id$
--

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


procedure write_boundary
   (io_conn  in out nocopy utl_smtp.connection,
    in_last  in boolean default false)
is
begin
   if in_last then
      utl_smtp.write_data(io_conn, LAST_BOUNDARY);
   else
      utl_smtp.write_data(io_conn, FIRST_BOUNDARY);
   end if;
end write_boundary;


procedure begin_attachment
   (io_conn         in out nocopy utl_smtp.connection,
    in_mime_type    in varchar2 default 'text/plain',
    in_inline       in boolean  default true,
    in_filename     in varchar2 default null,
    in_transfer_enc in varchar2 default null)
is
begin
   write_boundary(io_conn);
   write_mime_header(io_conn, 'Content-Type', in_mime_type);

   if in_inline then
	   write_mime_header(io_conn, 'Content-Disposition', 'inline; filename="'
            ||in_filename||'"');
   else
	   write_mime_header(io_conn, 'Content-Disposition', 'attachment; filename="'
            ||in_filename||'"');
   end if;

   if in_transfer_enc is not null then
      write_mime_header(io_conn, 'Content-Transfer-Encoding', in_transfer_enc);
   end if;

   utl_smtp.write_data(io_conn, utl_tcp.crlf);
end begin_attachment;


procedure write_attachment
   (io_conn     in out nocopy utl_smtp.connection,
    in_filename in varchar2)
is
   l_handle utl_file.file_type;
   l_line varchar2(128);
begin
   l_handle := utl_file.fopen('UTL_DIR',in_filename,'r');
   loop
      begin
         utl_file.get_line(l_handle, l_line);
         write_text(io_conn, l_line||utl_tcp.crlf);
      exception
         when OTHERS then
            exit;
      end;
   end loop;
   utl_file.fclose(l_handle);
end write_attachment;


procedure end_attachment
   (io_conn in out nocopy utl_smtp.connection,
    in_last in boolean default false)
is
begin
   utl_smtp.write_data(io_conn, utl_tcp.crlf);
   if in_last then
      write_boundary(io_conn, in_last);
   end if;
end end_attachment;


procedure attach_text
   (io_conn in out nocopy utl_smtp.connection,
    in_filename     in varchar2 default null,
    in_mime_type    in varchar2 default 'text/plain',
    in_inline       in boolean  default true,
    in_last         in boolean  default true)
is
begin
   utl_smtp.write_data(io_conn, utl_tcp.crlf);
   utl_smtp.write_data(io_conn, utl_tcp.crlf);
   begin_attachment(io_conn, in_mime_type, in_inline, in_filename);
   write_attachment(io_conn, in_filename);
   end_attachment(io_conn, in_last);
end attach_text;


-- Private functions


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


function begin_mail
   (in_sender     in varchar2,
    in_recipients in varchar2,
    in_subject    in varchar2,
    in_mime_type  in varchar2    default 'text/plain',
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
   l_conn := utl_smtp.open_connection(zci.default_value('SMTP_HOST'),
         zci.default_value('SMTP_PORT'));
   utl_smtp.ehlo(l_conn, zci.default_value('SMTP_DOMAIN'));

   -- perform authentication (if required)
   if (l_user is not null) and (l_pass is not null) then
      utl_smtp.command(l_conn, 'AUTH LOGIN');
      utl_smtp.command(l_conn,
            utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(l_user))));
      utl_smtp.command(l_conn,
            utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(l_pass))));
   end if;

   -- Specify sender's address
   utl_smtp.mail(l_conn, get_address(l_sender));

   -- Specify recipient(s) of the email.
   while (l_recipients is not null) loop
      utl_smtp.rcpt(l_conn, get_address(l_recipients));
   end loop;

   -- Start body of email
   utl_smtp.open_data(l_conn);

   -- Set "From" MIME header
   write_mime_header(l_conn, 'From', in_sender);

   -- Set "To" MIME header
   write_mime_header(l_conn, 'To', in_recipients);

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

   if (in_mime_type like 'multipart/mixed%') then
      write_text(l_conn, 'This is a multi-part message in MIME format.' || utl_tcp.crlf);
   end if;

   return l_conn;
end;


-- Public procedures


procedure send_msg
   (in_recipients in varchar2,
    in_subject    in varchar2,
    in_message    in varchar2,
    in_attachment in varchar2)
is
   l_msg varchar2(255);
   l_conn utl_smtp.connection;
begin
   l_conn := begin_mail(nvl(zci.default_value('SMTP_SENDER'),
         'synapse@'||zci.default_value('SMTP_DOMAIN')), in_recipients, in_subject);
   write_text(l_conn, in_message);

   if in_attachment is not null then
      attach_text(l_conn, in_attachment);
   end if;

   utl_smtp.close_data(l_conn);
   utl_smtp.quit(l_conn);
exception
   when OTHERS then
      zms.log_msg('Mail', null, null, sqlerrm, 'E', null, l_msg);
end send_msg;

end zmail;
/
show error package body zmail;

exit;
