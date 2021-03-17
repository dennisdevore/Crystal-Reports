--
-- $Id$
--
alter table custitem add
(
   sara_reportable1      char(1),
   sara_reportable2      char(1),
   sara_reportable3      char(1),
   sara_reportable4      char(1),
   sara_reportable5      char(1),
   sara_reportable6      char(1),
   sara_reportable7      char(1),
   sara_reportable8      char(1),
   sara_reportable9      char(1),
   sara_reportable10     char(1),
   sara_reportable11     char(1),
   sara_reportable12     char(1),
   sara_reportable13     char(1),
   sara_reportable14     char(1),
   sara_reportable15     char(1),
   sara_reportable16     char(1),
   sara_reportable17     char(1),
   sara_reportable18     char(1),
   sara_reportable19     char(1),
   sara_reportable20     char(1),
   sds_validation        char(1)
);
commit;

update custitem
set sara_reportable1 = decode(sara_cas_number1,null,null,'Y'),
    sara_reportable2 = decode(sara_cas_number2,null,null,'Y'),
    sara_reportable3 = decode(sara_cas_number3,null,null,'Y'),
    sara_reportable4 = decode(sara_cas_number4,null,null,'Y'),
    sara_reportable5 = decode(sara_cas_number5,null,null,'Y'),
    sara_reportable6 = decode(sara_cas_number6,null,null,'Y'),
    sara_reportable7 = decode(sara_cas_number7,null,null,'Y'),
    sara_reportable8 = decode(sara_cas_number8,null,null,'Y'),
    sara_reportable9 = decode(sara_cas_number9,null,null,'Y'),
    sara_reportable10 = decode(sara_cas_number10,null,null,'Y'),
    sara_reportable11 = decode(sara_cas_number11,null,null,'Y'),
    sara_reportable12 = decode(sara_cas_number12,null,null,'Y'),
    sara_reportable13 = decode(sara_cas_number13,null,null,'Y'),
    sara_reportable14 = decode(sara_cas_number14,null,null,'Y'),
    sara_reportable15 = decode(sara_cas_number15,null,null,'Y'),
    sara_reportable16 = decode(sara_cas_number16,null,null,'Y'),
    sara_reportable17 = decode(sara_cas_number17,null,null,'Y'),
    sara_reportable18 = decode(sara_cas_number18,null,null,'Y'),
    sara_reportable19 = decode(sara_cas_number19,null,null,'Y'),
    sara_reportable20 = decode(sara_cas_number20,null,null,'Y'),
    sds_validation = nvl(sds_validation,'N');

exit;
