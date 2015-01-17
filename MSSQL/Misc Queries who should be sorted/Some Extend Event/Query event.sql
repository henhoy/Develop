USE [tempdb];
GO

DECLARE 
	@path NVARCHAR(260) = 'c:\temp\wait*.etx', 
	@mdpath NVARCHAR(260) = 'c:\temp\wait*.mta', 
	@initial_file_name NVARCHAR(260) = NULL, 
	@initial_offset BIGINT = NULL 

SELECT top 1000
	pivoted_data.* 
FROM 
( 
	SELECT 
		MIN(event_name) as event_name,
		CONVERT 
		( 
			VARCHAR(MAX), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'wait_type' and 
						d_package IS NULL 
							THEN d_text
				END 
			) 
		) AS [wait_type], 
		MIN(event_timestamp) as event_timestamp, 
		unique_event_id, 
		CONVERT 
		( 
			VARCHAR(MAX), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'collect_cpu_cycle_time' and 
						d_package IS NOT NULL 
							THEN d_value
				END 
			) 
		) AS [collect_cpu_cycle_time],
		CONVERT 
		( 
			VARCHAR(MAX), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'collect_system_time' and 
						d_package IS NOT NULL 
							THEN d_value
				END 
			) 
		) AS [collect_system_time],
		CONVERT ( VARCHAR(MAX), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'plan_handle' and 
						d_package IS NOT NULL 
							THEN d_value
				END 
			) 
		) AS [plan_handle],
		CONVERT 
		( 
			VARCHAR(MAX), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'session_id' and 
						d_package IS NOT NULL 
							THEN d_value
				END 
			) 
		) AS [session_id],
		CONVERT 
		( 
			VARCHAR(MAX), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'sql_text' and 
						d_package IS NOT NULL 
							THEN d_value
				END 
			) 
		) AS [sql_text],
		CONVERT 
		( 
			BIGINT, 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'cpu' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [cpu],
		CONVERT 
		( 
			BIGINT, 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'duration' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [duration],
		CONVERT 
		( 
			BIGINT, 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'object_id' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [object_id],
		CONVERT 
		( 
			INT, 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'object_type' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [object_type],
		CONVERT 
		( 
			DECIMAL(28,0), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'reads' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [reads],
		CONVERT 
		( 
			INT, 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'source_database_id' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [source_database_id],
		CONVERT 
		( 
			DECIMAL(28,0), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'writes' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [writes],
		CONVERT 
		( 
			INT, 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'nest_level' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [nest_level],
		CONVERT 
		( 
			INT, 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'offset' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [offset],
		CONVERT 
		( 
			INT, 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'offset_end' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [offset_end],
		CONVERT 
		( 
			VARCHAR(MAX), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'state' and 
						d_package IS NULL 
							THEN d_text
				END 
			) 
		) AS [state],
		CONVERT 
		( 
			DECIMAL(28,0), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'completed_count' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [completed_count],
		CONVERT 
		( 
			DECIMAL(28,0), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'max_duration' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [max_duration],
		CONVERT 
		( 
			VARCHAR(MAX), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'opcode' and 
						d_package IS NULL 
							THEN d_text
				END 
			) 
		) AS [opcode],
		CONVERT 
		( 
			DECIMAL(28,0), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'signal_duration' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [signal_duration],
		CONVERT 
		( 
			DECIMAL(28,0), 
			MIN 
			( 
				CASE 
					WHEN 
						d_name = 'total_duration' and 
						d_package IS NULL 
							THEN d_value
				END 
			) 
		) AS [total_duration]
	FROM 
	( 
		SELECT 
			*
		FROM 
		( 
			SELECT 
				the_xml.event_name, 
				the_xml.file_name, 
				the_xml.file_offset, 
				the_xml.unique_event_id, 
				event_timestamp, 
				data_name AS d_name, 
				data_package AS d_package, 
				data_value AS d_value, 
				data_text AS d_text, 
				attach_activity_id 
			FROM 
			( 
				SELECT 
					CONVERT(xml, event_data), 
					object_name, 
					ROW_NUMBER() OVER (ORDER BY (SELECT 1)), 
					file_name, 
					file_offset 
				FROM sys.fn_xe_file_target_read_file (@path, @mdpath, @initial_file_name, @initial_offset) 
			) AS the_xml(event, event_name, unique_event_id, file_name, file_offset) 
			CROSS APPLY xe_event_reader(event) AS q 
		) AS data_data 
	) AS activity_data 
	
	GROUP BY 
		unique_event_id 
) AS pivoted_data
where 1=1
--and session_id = 112
--and event_name = 'wait_info'
and duration > 1000
order by unique_event_id
