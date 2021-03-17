CREATE OR REPLACE VIEW SAGE_HDR
   ( RECTYPE, CNTBTCH, CNTITEM, IDCUST, IDINVC, SPECINST, CUSTPO, DATEINVC, TEXTTRX)
   as select
      '1', '1', '1', custid, invoice, null, null, postdate, '1'
   from posthdr;

CREATE OR REPLACE VIEW SAGE_DTL
   (RECTYPE,CNTBTCH,CNTITEM,CNTLINE,TEXTDESC,AMTEXTN,IDITEM,UNITMEAS,NULLCOMMENT)
   as select
      '1','1','1','1',null,billedamt,item,calceduom,null  from invoicedtl;


exit;

