--SELECT * FROM idx.MaintenanceStatus


--SELECT * FROM idx.MaintenanceLog where database_name = 'TEST_DB' and object_name = 'frag_idx'

SELECT avg_fragmentation_in_percent_before, avg_fragmentation_in_percent_after, page_count_before, page_count_after,
       convert(decimal(18,2),(1-(page_count_after/convert(decimal(18,2), page_count_before)))*100) as parge_reduction,

FROM idx.MaintenanceLog 
where database_name = 'TEST_DB' and object_name = 'frag_idx'