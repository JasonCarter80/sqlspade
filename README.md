
SPADE simplifies the process of standing up a new SQL Server instance by applying standard Operating System pre-configurations, Installing SQL Server and then applying post-configurations and creating standard objects.

SPADE is a tool that is designed to speed up your standard deploymets of SQL Server. You may be saying "But I can already do an unsattended install"...but that's not all that's involved in most server builds. There are Operating System configurations like Microsoft Distrubuted Transaction Coordinator (MSDTC), Local Security Policy and others. I'm sure that you also have standard SQL objects that need to be deployed like Stored Procedures, Agent Jobs, Operators, etc. All of this can be done by SPADE automatically by running 1 simple PowerShell script.

Every organization is different, so this tool has been built so that it can easily be customized without requiring you to be a master of PowerShell. A simple XML configuration file defines the options for your standard build. For those non-standard, or "one-off" builds, the script has been defined so that you can change things for a single build without having to change the configuration file.

The current release supports standalone installs of SQL 2005, 2008, 2008R2, 2012, 2014, and 2016 (2017 will be supported soon).
