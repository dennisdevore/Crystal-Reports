--
-- $Id$
--
drop sequence cancelledid;
create sequence cancelledid
   increment by 1
   start with 1
   maxvalue   9999999
   minvalue   1
   nocache
   cycle;

drop sequence cntseq;
create sequence cntseq
   increment by 1
   start with 1
   maxvalue   9999999999
   minvalue   1
   nocache
   cycle;

drop sequence controlnumberseq;
create sequence controlnumberseq
   increment by 1
   start with 1
   maxvalue   9999999999
   minvalue   1
   nocache
   cycle;

drop sequence invoiceseq;
create sequence invoiceseq
   increment by 1
   start with 1
   maxvalue   99999999
   minvalue   1
   nocache
   cycle;

drop sequence loadseq;
create sequence loadseq
   increment by 1
   start with 1
   maxvalue   9999999
   minvalue   1
   nocache
   cycle;

drop sequence lpidseq;
create sequence lpidseq
   increment by 1
   start with 500000000000000
   maxvalue   999999999999999
   minvalue   1
   nocache
   cycle;

drop sequence masterinvseq;
create sequence masterinvseq
   increment by 1
   start with 1000
   maxvalue   99999999
   minvalue   1
   nocache
   cycle;

drop sequence orderseq;
create sequence orderseq
   increment by 1
   start with 1
   maxvalue   9999999
   minvalue   1
   nocache
   cycle;

drop sequence physicalinventoryseq;
create sequence physicalinventoryseq
   increment by 1
   start with 1
   maxvalue   99999999
   minvalue   1
   nocache
   cycle;

drop sequence qcrequestseq;
create sequence qcrequestseq
   increment by 1
   start with 1
   maxvalue   99999999
   minvalue   1
   nocache
   cycle;

drop sequence rmaseq;
create sequence rmaseq
   increment by 1
   start with 10000
   maxvalue   999999999999999
   minvalue   1
   nocache
   cycle;

drop sequence shippinglpidseq;
create sequence shippinglpidseq
   increment by 1
   start with 1
   maxvalue   99999999999999
   minvalue   1
   nocache
   cycle;

drop sequence taskseq;
create sequence taskseq
   increment by 1
   start with 1
   maxvalue   999999999999999
   minvalue   1
   nocache
   cycle;

drop sequence tempinvseq;
create sequence tempinvseq
   increment by 1
   start with 1
   maxvalue   9999
   minvalue   1
   nocache
   cycle;

drop sequence vlpidseq;
create sequence vlpidseq
 increment by 1
 start with 999000000000000
 maxvalue   999999999999999
 minvalue   1
 nocache
 cycle;

drop sequence waveseq;
create sequence waveseq
   increment by 1
   start with 1
   maxvalue   9999999
   minvalue   1
   nocache
   cycle;

drop sequence workorderseq;
create sequence workorderseq
   increment by 1
   start with 1
   maxvalue   99999999
   minvalue   1
   nocache
   cycle;

exit;
