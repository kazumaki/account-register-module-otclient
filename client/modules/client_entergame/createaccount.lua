CreateAccount = { }

local createAccountWindow

function CreateAccount.init()
  createAccountWindow = g_ui.displayUI('createaccount')
  CreateAccount.hide()
end

function CreateAccount.terminate()
  createAccountWindow:destroy()
  createAccountWindow = nil
end

function CreateAccount.show()
  createAccountWindow:show()
  createAccountWindow:raise()
  createAccountWindow:focus()
end

function CreateAccount.doOpenEnterGameWindow()
  CreateAccount.hide()
  EnterGame.show()
end

local function onError(protocol, message, errorCode)
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end
  
  local errorBox = displayErrorBox(tr('Create Account Error'), message)
  connect(errorBox, { onOk = CreateAccount.show })
end

local function onSuccess(message)
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end

  createAccountSuccessWindow = displayInfoBox(tr('Create Account'), message)
  createAccountSuccessWindow.onOk = {
    function()
      createAccountSuccessWindow = nil
      CreateAccount.hide()
      EnterGame.show()
    end
  }
end

function CreateAccount.doCreateAccount()
  createAccountName = createAccountWindow:getChildById('accountNameTextEdit'):getText()
  createEmail = createAccountWindow:getChildById('emailTextEdit'):getText()
  createPassword = createAccountWindow:getChildById('passwordTextEdit'):getText()
  createPasswordConfirmation = createAccountWindow:getChildById('passwordConfirmationTextEdit'):getText()
  host = '127.0.0.1'
  port = tonumber('7174')
  local clientVersion = tonumber('1098')

  CreateAccount.hide()

  if g_game.isOnline() then
    local errorBox = displayErrorBox(tr('Create Account Error'), tr('Cannot create account while already in game.'))
    connect(errorBox, { onOk = CreateAccount.show() })
    return
  end

  protocolCreateAccount = ProtocolCreateAccount.create()
  protocolCreateAccount.onCreateAccountError = onError
  protocolCreateAccount.onCreateAccountSuccess = onSuccess

  loadBox = displayCancelBox(tr('Please wait'), tr('Connecting to create account server...'))
  connect(loadBox, { onCancel = function(msgbox)
                                  loadBox = nil
                                  protocolCreateAccount:cancelCreateAccount()
                                  CreateAccount.show()
                                end})

  g_game.setClientVersion(clientVersion)
  g_game.setProtocolVersion(g_game.getClientProtocolVersion(clientVersion))
  g_game.chooseRsa(host)

  protocolCreateAccount:createAccount(host, port, createAccountName, createEmail, createPassword, createPasswordConfirmation)
end

function CreateAccount.hide()
  createAccountWindow:hide()
end