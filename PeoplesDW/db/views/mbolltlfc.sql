CREATE OR REPLACE VIEW MBOLLTLFC ( LOADNO,
CUSTID, LTLFC, DESCR, QTY,
WEIGHT, CUBESHIP, CASEQTY ) AS select SP.loadno,
       SP.custid,
       CI.ltlfc,
       nvl(L.descr,'NO LTLFC DESCRIPTION'),
       sum(nvl(quantity,0)),
       sum(SP.weight),
       sum(LD.cubeship),
       sum(zbut.translate_uom_function
            (SP.custid,SP.item,nvl(quantity,0),SP.unitofmeasure,'CS'))
  from ltlfreightclass L, custitem CI, shippingplate SP, loads LD
 where SP.custid = CI.custid(+)
   and SP.item   = CI.item(+)
   and CI.ltlfc = L.code (+)
   and SP.loadno = LD.loadno (+)
   and SP.type in ('F','P')
  group by SP.loadno, SP.custid, CI.ltlfc, nvl(L.descr,'NO LTLFC DESCRIPTION');
  
comment on table MBOLLTLFC is '$Id';
  
exit;
