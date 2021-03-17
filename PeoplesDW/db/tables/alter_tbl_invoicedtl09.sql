--
-- alter_tbl_invoicedtl09.sql
--
alter table invoicedtl add
(
   invoicedtlkey     number(38)
);
declare
   cursor invoicedtl_cur is
         select rowid
           from invoicedtl
          where invoicedtlkey is null;
           
   type invoicedtl_tbl is table of rowid;
   invoicedtl_row invoicedtl_tbl;
   l_dtl_rows pls_integer;
   l_invoicedtl_rows pls_integer := 0;

begin

   open invoicedtl;
   loop

      fetch invoicedtl_cur bulk collect
       into invoicedtl_row limit 100000;
  
      if invoicedtl_row.count = 0 then
         exit;
      end if;

      forall i in invoicedtl_row.first .. invoicedtl_row.last
         update invoicedtl
            set invoicedtlkey = invoicedtlseq.nextval;
         where rowid = appmsgs_row(i);

      l_dtl_rows := sql%rowcount;
      l_invoicedtl_rows := l_invoicedtl_rows + l_dtl_rows;

      commit;

   end loop;

   zut.prt('Total rows processed: ' || l_invoicedtl_Rows);

exception when others then
   zut.prt('rows processed: ' || l_invoicedtl_Rows);
   zut.prt('Others error: '||DBMS_UTILITY.FORMAT_ERROR_STACK
                           ||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
end;
/
commit;
alter table invoicedtl
   modify(invoicedtlkey not null);

exit;
