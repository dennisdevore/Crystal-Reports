1. copy the selected_export_import to the /tmp directory
   of the source db server
2. ssh into the source db server:
    a. cd /tmp/selected_export_import/scripts
    b. . ./export_for.order.sh 11111 2
       (where 11111 is orderid and 2 is shipid)
3. copy the /tmp/selected_export_import directory from
   the source server to the destination server
4. ssh into the destination db server:
   a. as oracle user (NOTE: this will destroy all schema/data in the instance)
      i.   cd /tmp/selected_export_import/scripts
      ii.  . ./recreate_alps_as_oracle.sh
   b  as synapse user
      i.   cd /tmp/selected_export_import/scripts
      ii.  . . ./import.sh ../dumps/exp_order_11111_2_ALL.dmp.gz
   
you're done :)
