declare
  l_task       VARCHAR2 (30) := 'task_travllers_event_cleanup';
  l_task_count NUMBER(1);
  l_sql_stmt   VARCHAR2 (4000);
  --
begin
  --dbms_output.put_line('- creating cleanup task');
  SELECT count(1) INTO l_task_count FROM  user_parallel_execute_tasks WHERE task_name=l_task;
   
  IF l_task_count = 0 THEN
    DBMS_PARALLEL_EXECUTE.create_task (task_name => l_task);
  ELSE
    DBMS_PARALLEL_EXECUTE.drop_task (l_task);
    DBMS_PARALLEL_EXECUTE.create_task (task_name => l_task);
  END IF;
  
  DBMS_PARALLEL_EXECUTE.create_chunks_by_rowid (
    task_name     => l_task,
    table_owner   => USER,
    table_name    => 'TRAVELLERS',
    by_row        => TRUE,
    chunk_size    => 1000);

   l_sql_stmt := 'update /*+ ROWID(TRAVELLERS) */ travellers
				  set event_id = null
				  WHERE rowid BETWEEN :start_id AND :end_id';

   DBMS_PARALLEL_EXECUTE.run_task (task_name        => l_task,
                                   sql_stmt         => l_sql_stmt,
                                   language_flag    => DBMS_SQL.native,
                                   parallel_level   => 4);

end;
/
