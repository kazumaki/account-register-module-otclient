#include "otpch.h"

#include "protocolcreatecharacter.h"

#include "outputmessage.h"
#include "tasks.h"

#include "configmanager.h"
#include "iocreatecharacterdata.h"
#include "iologindata.h"
#include "ban.h"
#include "game.h"

#include <fmt/format.h>

extern ConfigManager g_config;
extern Game g_game;

void ProtocolCreateCharacter::disconnectClient(const std::string& message, uint16_t version)
{
	auto output = OutputMessagePool::getOutputMessage();

	output->addByte(version >= 1076 ? 0x0B : 0x0A);
	output->addString(message);
	send(output);

	disconnect();
}

void ProtocolCreateCharacter::doCreateCharacter(const std::string& accountName, const std::string& password, const std::string& characterName, uint16_t version) {
	Account account;
	if (!IOCreateCharacterData::isCharacterNameValid(characterName)) {
		disconnectClient("Character name is invalid.", version);
		return;
	}

	if (IOCreateCharacterData::doesCharacterNameExist(characterName)) {
		disconnectClient("Character name already exist.", version);
		return;
	}

	if (!IOLoginData::loginserverAuthentication(accountName, password, account)) {
		disconnectClient("Unable to authenticate user.", version);
		return;
	}

	if (!IOCreateCharacterData::insertCharacter(account, characterName)) {
		disconnectClient("Something went wrong, please contact administrator!", version);
		return;
	}

	auto output = OutputMessagePool::getOutputMessage();

	output->addByte(0xFF);
	output->addString("Congratulations, your character has been created");

	send(output);

	disconnect();
}

void ProtocolCreateCharacter::onRecvFirstMessage(NetworkMessage& msg)
{
	if (g_game.getGameState() == GAME_STATE_SHUTDOWN) {
		disconnect();
		return;
	}

	msg.skipBytes(2); // client OS

	uint16_t version = msg.get<uint16_t>();
	if (version >= 971) {
		msg.skipBytes(17);
	}
	else {
		msg.skipBytes(12);
	}

	if (version <= 760) {
		disconnectClient(fmt::format("Only clients with protocol {:s} allowed!", CLIENT_VERSION_STR), version);
		return;
	}

	if (!Protocol::RSA_decrypt(msg)) {
		disconnect();
		return;
	}

	xtea::key key;
	key[0] = msg.get<uint32_t>();
	key[1] = msg.get<uint32_t>();
	key[2] = msg.get<uint32_t>();
	key[3] = msg.get<uint32_t>();
	enableXTEAEncryption();
	setXTEAKey(std::move(key));

	if (version < CLIENT_VERSION_MIN || version > CLIENT_VERSION_MAX) {
		disconnectClient(fmt::format("Only clients with protocol {:s} allowed!", CLIENT_VERSION_STR), version);
		return;
	}

	if (g_game.getGameState() == GAME_STATE_STARTUP) {
		disconnectClient("Gameworld is starting up. Please wait.", version);
		return;
	}

	if (g_game.getGameState() == GAME_STATE_MAINTAIN) {
		disconnectClient("Gameworld is under maintenance.\nPlease re-connect in a while.", version);
		return;
	}

	BanInfo banInfo;
	auto connection = getConnection();
	if (!connection) {
		return;
	}

	if (IOBan::isIpBanned(connection->getIP(), banInfo)) {
		if (banInfo.reason.empty()) {
			banInfo.reason = "(none)";
		}

		disconnectClient(fmt::format("Your IP has been banned until {:s} by {:s}.\n\nReason specified:\n{:s}", formatDateShort(banInfo.expiresAt), banInfo.bannedBy, banInfo.reason), version);
		return;
	}

	std::string accountName = msg.getString();
	if (accountName.empty()) {
		disconnectClient("Invalid account name.", version);
		return;
	}

	std::string password = msg.getString();
	if (password.empty()) {
		disconnectClient("Invalid password.", version);
		return;
	}

	std::string characterName = msg.getString();
	if (characterName.empty()) {
		disconnectClient("Invalid character name.", version);
		return;
	}

	auto thisPtr = std::static_pointer_cast<ProtocolCreateCharacter>(shared_from_this());
	g_dispatcher.addTask(createTask(std::bind(&ProtocolCreateCharacter::doCreateCharacter, thisPtr, accountName, password, characterName, version)));
}
