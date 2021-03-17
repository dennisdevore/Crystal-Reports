create or replace view d_activity as
select
      sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
      a.lastupdate Modification_Time,
      a.CODE Activity,
      a.DESCR  Activity_descr,
      a.ABBREV Activity_Abbrev,
      a.GLACCT GL_Acct,
      a.MINCATEGORY Min_Category,
      a.REVENUEGROUP Revenue_Group,
      a.IRISCLASS  Iris_Class,
      a.IRISNAME   Iris_Name,
      a.IRISCHARGE Iris_Charge,
      a.IRISTYPE   Iris_Type,
      a.IRISORDER  Iris_Order,
      a.LASTUSER   Last_Update_User,
      a.LASTUPDATE Last_Update_Time
from  alps.activity a;