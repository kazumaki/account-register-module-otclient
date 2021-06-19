#include "iocreatecharacterdata.h"

bool IOCreateCharacterData::isCharacterNameValid(const std::string& characterName) {
	return std::regex_match(characterName, std::regex("^[a-zA-Z ]{3,}$"));
}

bool IOCreateCharacterData::doesCharacterNameExist(const std::string& characterName) {
	Database& db = Database::getInstance();

	std::ostringstream query;
	query << "SELECT `id` FROM `players` WHERE `name` = " << db.escapeString(characterName);
	DBResult_ptr result = db.storeQuery(query.str());

	if (result) {
		return true;
	}

	return false;
}

bool IOCreateCharacterData::insertCharacter(const Account account, const std::string& characterName) {
	Database& db = Database::getInstance();
	std::ostringstream query;
	query << "INSERT INTO `players` (`name`, `account_id`, `conditions`) VALUES ('" << characterName << "', '" << account.id << "', '""')";
	if (db.executeQuery(query.str())) {
		return true;
	}

	return false;
}
