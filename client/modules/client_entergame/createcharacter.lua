CreateCharacter = {}

local createCharacterWindow
local loadBox

local function onError(protocol, message, errorCode)
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end

  local errorBox = displayErrorBox(tr('Create Character Error'), message)
  connect(errorBox, { onOk = CreateCharacter.show })
end

local function onSuccess(message)
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end

  createCharacterSuccessWindow = displayInfoBox(tr('Create Character'), message)
  createCharacterSuccessWindow.onOk = {
    function()
      createCharacterSuccessWindow = nil
      CreateCharacter.hide()
      EnterGame.doLoginAgain()
    end
  }
end

function CreateCharacter.init()
  createCharacterWindow = g_ui.displayUI('createcharacter')
  CreateCharacter.hide()
end

function CreateCharacter.terminate()
  createCharacterWindow:destroy()
  createCharacterWindow = nil
  loadBox = nil
end

function CreateCharacter.show()
  createCharacterWindow:show()
  createCharacterWindow:raise()
  createCharacterWindow:focus()
end

function CreateCharacter.doOpenCharacterList()
  CreateCharacter.hide()
  CharacterList.show()
end

function CreateCharacter.doCreateCharacter()
  characterName = createCharacterWindow:getChildById('characterNameTextEdit'):getText()
  CreateCharacter.hide()
  host = '127.0.0.1'
  port = tonumber('7173')

  if g_game.isOnline() then
    local errorBox = displayErrorBox(tr('Create Character Error'), tr('Cannot create character while already in game.'))
    connect(errorBox, { onOk = CreateCharacter.show() })
    return
  end

  protocolCreateCharacter = ProtocolCreateCharacter.create()
  protocolCreateCharacter.onCreateCharacterError = onError
  protocolCreateCharacter.onCreateCharacterSuccess = onSuccess

  loadBox = displayCancelBox(tr('Please wait'), tr('Connecting to create characterServer'))
  connect(loadBox, { onCancel = function(msgbox)
                                  loadBox = nil
                                  CreateCharacter.show()
                                end})

  protocolCreateCharacter:createCharacter(host, port, G.account, G.password, characterName)
end

function CreateCharacter.hide(showCharacterList)
  if not createCharacterWindow then return end
  showCharacterList = showCharacterList or false

  createCharacterWindow:hide()

  if showCharacterList and CharacterList then
    CharacterList.show()
  end
end