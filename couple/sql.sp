// SQL queries for the cp_proposals table.

new String:sql_createProposals[] =
	"CREATE TABLE IF NOT EXISTS cp_proposals (source_name VARCHAR(64), source_id VARCHAR(64) PRIMARY KEY, target_name VARCHAR(64), target_id VARCHAR(64));";

new String:sql_resetProposals[] = 
	"DELETE FROM cp_proposals;";	
	
new String:sql_addProposal[] = 
	"INSERT INTO cp_proposals VALUES ('%s', '%s', '%s', '%s');";
	
new String:sql_deleteProposalsSource[] =
	"DELETE FROM cp_proposals WHERE source_id = '%s';";
	
new String:sql_deleteProposalsTarget[] = 
	"DELETE FROM cp_proposals WHERE target_id = '%s';";
	
new String:sql_getProposals[] = 
	"SELECT source_name, source_id FROM cp_proposals WHERE target_id = '%s';";
	
new String:sql_getAllProposals[] = 
	"SELECT * FROM cp_proposals WHERE source_id ='%s' OR target_id = '%s';";
	
new String:sql_updateProposalSource[] = 
	"UPDATE cp_proposals SET source_name = '%s' WHERE source_id = '%s';";
	
new String:sql_updateProposalTarget[] = 
	"UPDATE cp_proposals SET target_name = '%s' WHERE target_id = '%s';";
	

// SQL queries for the cp_marriages table.

new String:sql_createMarriages[] =
	"CREATE TABLE IF NOT EXISTS cp_marriages (source_name VARCHAR(64), source_id VARCHAR(64) , target_name VARCHAR(64), target_id VARCHAR(64), score INT(11) unsigned, timestamp INT(11) unsigned);";
	
new String:sql_resetMarriages[] = 
	"DELETE FROM cp_marriages;";
	
new String:sql_addMarriage[] = 
	"INSERT INTO cp_marriages VALUES ('%s', '%s', '%s', '%s', %i, %i);";	
	
new String:sql_revokeMarriage[] = 
	"DELETE FROM cp_marriages WHERE source_id ='%s' OR target_id = '%s';";	
	
new String:sql_getMarriage[] = 
	"SELECT * FROM cp_marriages WHERE source_id = '%s' OR target_id = '%s';";	
	
new String:sql_getMarriages[] = 
	"SELECT * FROM cp_marriages ORDER BY score DESC LIMIT %i;";	
	
new String:sql_updateMarriageSource[] = 
	"UPDATE cp_marriages SET source_name = '%s' WHERE source_id = '%s';";
	
new String:sql_updateMarriageTarget[] = 
	"UPDATE cp_marriages SET target_name = '%s' WHERE target_id = '%s';";
	
new String:sql_updateMarriageScore[] = 
	"UPDATE cp_marriages SET score = '%i' WHERE source_id = '%s' OR target_id = '%s';";