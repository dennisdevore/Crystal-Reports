SELECT c.abbrev                              AS revtype,
          c.descr                               AS revtypedescr,
          NULL                                  AS revsubtype,
          NULL                                  AS revsubtypedescr,
          invoice,
          facility,
          custid,
          invdate,
          activity,
          billedqty,
          billedamt,
          revenuegroup,
          zdtc.firstOfMonth (invdate)           AS firstofmonth,
          zdtc.firstOfWeekSunToSat (invdate)    AS firstOfWeek,
          1                                     AS truelink
     FROM aprbldinvdtlview a, activity b, invoicetypes c
    WHERE     a.activity = b.code
          AND invtype = 'A'
          AND invtype = c.code
          AND b.revenuegroup NOT IN (SELECT code
                                       FROM revenurptbackoutview
                                      WHERE invtype = 'A')
                                           and invoice = 3818386