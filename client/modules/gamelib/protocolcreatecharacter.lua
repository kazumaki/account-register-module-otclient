-- @docclass
ProtocolCreateCharacter = extends(Protocol, "ProtocolCreateCharacter")

function ProtocolCreateCharacter:createCharacter(host, port, accountName, password, characterName)
  if string.len(host) == 0 or port == nil or port == 0 then
    signalcall(self.onCreateCharacterError, self, tr("You must enter a valid server address and port."))
    return
  end

  self.accountName = accountName
  self.password = password
  self.characterName = characterName
  self.connectCallback = self.sendCreateCharacterPacket
  self:connect(host, port)
end

function ProtocolCreateCharacter:cancelCreateCharacter()
  self:disconnect()
end

function ProtocolCreateCharacter:sendCreateCharacterPacket()
  local msg = OutputMessage.create()

  msg:addU8(ClientOpcodes.ClientCreateCharacter)
  msg:addU16(g_game.getOs())

  msg:addU16(g_game.getProtocolVersion())

  if g_game.getFeature(GameClientVersion) then
    msg:addU32(g_game.getClientVersion())
  end

  if g_game.getFeature(GameContentRevision) then
    msg:addU16(g_things.getContentRevision())
    msg:addU16(0)
  else
    msg:addU32(g_things.getDatSignature())
  end
  msg:addU32(g_sprites.getSprSignature())
  msg:addU32(PIC_SIGNATURE)

  if g_game.getFeature(GamePreviewState) then
    msg:addU8(0)
  end

  local offset = msg:getMessageSize()

  if g_game.getFeature(GameLoginPacketEncryption) then
    -- first RSA byte must be 0
    msg:addU8(0)

    -- xtea key
    self:generateXteaKey()
    local xteaKey = self:getXteaKey()
    msg:addU32(xteaKey[1])
    msg:addU32(xteaKey[2])
    msg:addU32(xteaKey[3])
    msg:addU32(xteaKey[4])
  end
  
  msg:addString(self.accountName)
  msg:addString(self.password)
  msg:addString(self.characterName)

  local paddingBytes = g_crypt.rsaGetSize() - (msg:getMessageSize() - offset)

  assert(paddingBytes >= 0)
  for i = 1, paddingBytes do
    msg:addU8(math.random(0, 0xff))
  end

  if g_game.getFeature(GameLoginPacketEncryption) then
    msg:encryptRsa()
  end

  if g_game.getFeature(GameProtocolChecksum) then
    self:enableChecksum()
  end

  self:send(msg)
  if g_game.getFeature(GameLoginPacketEncryption) then
    self:enableXteaEncryption()
  end
  self:recv()
end

function ProtocolCreateCharacter:onConnect()
  self.gotConnection = true
  self:connectCallback()
  self.connectCallback = nil
end

function ProtocolCreateCharacter:onRecv(msg)

  while not msg:eof() do
    local opcode = msg:getU8()

    if opcode == 0xB then
      self:parseError(msg)
    elseif opcode == 255 then
      self:parseSuccess(msg)  
    end
  end
  self:disconnect()
end

function ProtocolCreateCharacter:parseSuccess(msg)
  local successMessage = msg:getString()
  self.onCreateCharacterSuccess(successMessage)
end

function ProtocolCreateCharacter:parseError(msg)
  local errorMessage = msg:getString()
  signalcall(self.onCreateCharacterError, self, errorMessage)
end

