/* 2005,2008,2008R2 */

/*****************************************************************************************************
 * Auto-Install Script Template
 *----------------------------------------------------------------------------------------------------
 *
 * Instructions:
 * The top line of this document must contain a commented comma seperated list of the versions of SQL 
 * that this script applies to.  Example: "/* 2000, 2005, 2008, 2008R2 */"
 * 
 * This script template is only suitable for statements that are to be executed as part of the 
 * auto-install process and must run only against the server instance being installed.
 *
 * The script must terminate each statement using the ";" operator and must not contain the keyword 
 * "GO". 
 *
 * This template does not support scripts that need to be called with parameters.  If your script 
 * requires parameters please use the PowerShell Script template.
 *
 * Scripts must be named using the following pattern:
 * level-level name-script name
 *
 * level: The numeric level of the script.  This controls the order in which scripts are applied to
 *		  ensure that dependancies are not broken.  See Level list for the possible values.
 *
 * level name: The friendly name of the level.  This is meant to makes the scripts more easily
 *			   identifiable.  See Level list for the possible values.
 *
 * script name: The friendly name of the script.  This should be short, but detailed enought to tell
 *				what the script will accomplish.
 *
 * Example: "300-Server-AddExtendedProperty.sql" - Server level script that adds the DBA Extended
 *			property to the master and model databases
 *
 * Level List:
 * ---------------
 * 300 - Server - Scripts that create/alter/drop server level objects and settings
 * 400 - Database - Scripts that create/alter/drop databases and settings
 * 500 - Table - Scripts that create/alter/drop tables, schemas, users, roles
 * 600 - View - Scripts that create/alter/drop views, indexes, or other objects with table dependancies
 * 700 - Procedure - Scripts that create/alter/drop objects with table/view dependancies
 * 800 - Agent - Scripts that create/alter/drop agent jobs, job steps, job schedules, notifications, etc
 *****************************************************************************************************/
 
/*****************************************************************************************************
 * Script Information
 *----------------------------------------------------------------------------------------------------
 *		Author: Michael Wells
 *		  Date: 12/1/2010
 * Description: Create the agent job that purges Database Mail history
 *	   History: 12/1/2010 Adapted for Auto-Install
 *****************************************************************************************************/
 
USE [msdb];

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DatabaseMail Cleanup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Archive mail and log over 1 month old]    Script Date: 10/29/2007 16:18:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Archive mail and log over 1 month old', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @CopyDate nvarchar(20) ;
SELECT @CopyDate = CONVERT(VARCHAR, DATEADD(MONTH, -1, GETDATE()), 101)

EXECUTE msdb.dbo.sysmail_delete_mailitems_sp @sent_before = @CopyDate ;
EXECUTE msdb.dbo.sysmail_delete_log_sp @logged_before = @CopyDate ;', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every month', 
		@enabled=1, 
		@freq_type=32, 
		@freq_interval=7, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=1, 
		@freq_recurrence_factor=1, 
		@active_start_date=20060328, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

