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
 *		Author: Unknown
 *		  Date: 6/24/1997
 * Description: Create the procedure used to cycle the SQL Error Log
 *	   History: 12/1/2010 - mwells1 - Adapted for Auto-Install
 *****************************************************************************************************/
 
use [master]
[GO]

create procedure sp_cycle_errorlog  --- 1997/06/24
as
if (not (is_srvrolemember('sysadmin') = 1))  -- Make sure that it is the SA executing this.
        begin
                raiserror(15247,-1,-1)
                return(1)
        end

dbcc errorlog
return (0)