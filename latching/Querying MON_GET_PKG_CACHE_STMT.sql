#List top 10 SQL with highest average latch wait time
#SQL
select substr(stmt_text,1,50) as stmt_text,decimal(float(total_extended_latch_wait_time)/num_executions,10,5)as avg_latch_time from table(mon_get_pkg_cache_stmt(null,null,null,null)) where num_executions > 0 order by avg_latch_time desc fetch first 10 rows only
#CMD LINE
db2 "select substr(stmt_text,1,50) as stmt_text,decimal(float(total_extended_latch_wait_time)/num_executions,10,5)as avg_latch_time from table(mon_get_pkg_cache_stmt(null,null,null,null)) where num_executions > 0 order by avg_latch_time desc fetch first 10 rows only"

# List all SQL ordered by TOTAL_EXTENDED_LATCH_WAIT_TIME
#SQL
SELECT TOTAL_EXTENDED_LATCH_WAIT_TIME, TOTAL_EXTENDED_LATCH_WAITS, NUM_EXEC_WITH_METRICS, COORD_STMT_EXEC_TIME, TOTAL_ACT_TIME, TOTAL_ACT_WAIT_TIME, TOTAL_CPU_TIME, SUBSTR( STMT_TEXT, 1, 2000 ) AS STMT_TEXT FROM TABLE(MON_GET_PKG_CACHE_STMT ( 'D', NULL, NULL, -2)) as T WHERE T.NUM_EXEC_WITH_METRICS <> 0 ORDER BY TOTAL_EXTENDED_LATCH_WAIT_TIME DESC FETCH FIRST 1000 ROWS ONLY
#CMD LINE
db2 "SELECT TOTAL_EXTENDED_LATCH_WAIT_TIME, TOTAL_EXTENDED_LATCH_WAITS, NUM_EXEC_WITH_METRICS, COORD_STMT_EXEC_TIME, TOTAL_ACT_TIME, TOTAL_ACT_WAIT_TIME, TOTAL_CPU_TIME, SUBSTR( STMT_TEXT, 1, 2000 ) AS STMT_TEXT FROM TABLE(MON_GET_PKG_CACHE_STMT ( 'D', NULL, NULL, -2)) as T WHERE T.NUM_EXEC_WITH_METRICS <> 0 ORDER BY TOTAL_EXTENDED_LATCH_WAIT_TIME DESC FETCH FIRST 1000 ROWS ONLY"

# List top 20 ordered by TOTAL_EXTENDED_LATCH_WAIT_TIME 
#SQL
SELECT TOTAL_EXTENDED_LATCH_WAIT_TIME, TOTAL_EXTENDED_LATCH_WAITS, NUM_EXEC_WITH_METRICS, COORD_STMT_EXEC_TIME, TOTAL_ACT_TIME, TOTAL_ACT_WAIT_TIME, TOTAL_CPU_TIME, SUBSTR( STMT_TEXT, 1, 2000 ) AS STMT_TEXT FROM TABLE(MON_GET_PKG_CACHE_STMT ( 'D', NULL, NULL, -2)) as T WHERE T.NUM_EXEC_WITH_METRICS <> 0 ORDER BY TOTAL_EXTENDED_LATCH_WAIT_TIME DESC FETCH FIRST 20 ROWS ONLY
#CMD LINE
db2 "SELECT TOTAL_EXTENDED_LATCH_WAIT_TIME, TOTAL_EXTENDED_LATCH_WAITS, NUM_EXEC_WITH_METRICS, COORD_STMT_EXEC_TIME, TOTAL_ACT_TIME, TOTAL_ACT_WAIT_TIME, TOTAL_CPU_TIME, SUBSTR( STMT_TEXT, 1, 2000 ) AS STMT_TEXT FROM TABLE(MON_GET_PKG_CACHE_STMT ( 'D', NULL, NULL, -2)) as T WHERE T.NUM_EXEC_WITH_METRICS <> 0 ORDER BY TOTAL_EXTENDED_LATCH_WAIT_TIME DESC FETCH FIRST 20 ROWS ONLY
"
# Check how much time is spent on latch waits for specifc SQL
#SQL
select NUM_EXECUTIONS, TOTAL_ACT_TIME, TOTAL_ACT_WAIT_TIME, TOTAL_EXTENDED_LATCH_WAIT_TIME, POOL_INDEX_L_READS, substr(stmt_text, 30, 150) from TABLE( MON_GET_PKG_CACHE_STMT(NULL, NULL, NULL, -2 ) ) where STMT_TEXT like '%STATEMENT%TEXT%'
#CMD LINE
db2 "select NUM_EXECUTIONS, TOTAL_ACT_TIME, TOTAL_ACT_WAIT_TIME, TOTAL_EXTENDED_LATCH_WAIT_TIME, POOL_INDEX_L_READS, substr(stmt_text, 30, 150) from TABLE( MON_GET_PKG_CACHE_STMT(NULL, NULL, NULL, -2 ) ) where STMT_TEXT like '%STATEMENT%TEXT%'"

# List current latches with timestamp for collection
#SQL
select current timestamp as collection_timestamp, substr(latch_name,1,70) as latch_name, total_extended_latch_waits as num_waits, total_extended_latch_wait_time as wait_time from table(mon_get_extended_latch_wait(-2)) as t order by
total_extended_latch_wait_time desc
#CMD LINE
db2 "select current timestamp as collection_timestamp, substr(latch_name,1,70) as latch_name, total_extended_latch_waits as num_waits, total_extended_latch_wait_time as wait_time from table(mon_get_extended_latch_wait(-2)) as t order by
total_extended_latch_wait_time desc"
