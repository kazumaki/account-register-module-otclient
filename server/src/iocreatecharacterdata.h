#pragma once
#include "database.h"
#include "account.h"
#include <regex>

class IOCreateCharacterData
{
	public:
		static bool isCharacterNameValid(const std::string& characterName);
		static bool doesCharacterNameExist(const std::string& characterName);

		static bool insertCharacter(const Account account, const std::string& characterName);
	private:

};
