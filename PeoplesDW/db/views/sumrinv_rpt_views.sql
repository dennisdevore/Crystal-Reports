create or replace force view sumrinv_view_rpt1
(
   masterinvoice,
   invoice,
   activityabbrev,
   billmethod,
   billmethodcount
)
as
   select distinct
          masterinvoice,
          0,
          activityabbrev,
          billmethod,
          (select count (distinct billmethod)
             from invitemrpt
            where masterinvoice = iv1.masterinvoice
                  and activityabbrev = iv1.activityabbrev)
             billmethodcount
     from invitemrpt iv1;

comment on table sumrinv_view_rpt1 is '$Id';

create or replace force view sumrinv_view_rpt2
(
   masterinvoice,
   invoice,
   activityabbrev,
   billmethod,
   billedamt
)
as
     select masterinvoice,
            invoice,
            activityabbrev,
            billmethod,
            sum (billedamt) billedamt
       from invitemrpt
   group by masterinvoice,
            invoice,
            activityabbrev,
            billmethod
   union
   select distinct iv1.masterinvoice,
                   iv2.invoice,
                   iv1.activityabbrev,
                   iv1.billmethod,
                   0.0
     from (select distinct masterinvoice, activityabbrev, billmethod
             from invitemrpt) iv1,
          invitemrpt iv2
    where iv2.masterinvoice = iv1.masterinvoice
          and not exists
                     (select 1
                        from invitemrpt iv3
                       where     iv3.masterinvoice = iv1.masterinvoice
                             and iv3.invoice = iv2.invoice
                             and iv3.activityabbrev = iv1.activityabbrev
                             and iv3.billmethod = iv1.billmethod);

comment on table sumrinv_view_rpt2 is '$id';

create or replace force view sumrinv_view_rpt3
(
   masterinvoice,
   activityabbrev,
   billmethod,
   billedamt
)
as
     select masterinvoice,
            activityabbrev,
            billmethod,
            sum (billedamt) billedamt
       from invitemrpt
   group by masterinvoice, activityabbrev, billmethod;

comment on table sumrinv_view_rpt3 is '$id';
