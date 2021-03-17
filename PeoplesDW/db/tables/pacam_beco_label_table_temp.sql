drop table pacam_beco_label_table_temp;

create global temporary table pacam_beco_label_table_temp
(
   orderid              number(9),
   shipid               number(2),
   lpid                 varchar2(15),
   fromlpid             varchar2(15),
   parentlpid           varchar2(15),
   from_name            varchar2(40),
   fromaddr1            varchar2(40),
   fromaddr2            varchar2(40),
   fromcsz              varchar2(50),
   toname               varchar2(40),
   toaddr1              varchar2(40),
   toaddr2              varchar2(40),
   tocsz                varchar2(50),
   tozip                varchar2(17),
   tobczip              varchar2(15),
   carname              varchar2(40),
   pro                  varchar2(20),
   bol                  varchar2(255),
   po                   varchar2(20),
   dept                 varchar2(10),
   style                varchar2(10),
   color                varchar2(10),
   isize                varchar2(10),
   units                number(7),
   item varchar2(50),
   lotnumber            varchar2(30),
   fordc                varchar2(15),
   bcfordc              varchar2(15),
   dc                   varchar2(15),
   sku                  varchar2(20),
   buildseq             number(7)
)
on commit delete rows;

exit;
