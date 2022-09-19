local screen = guiGetScreenSize();
local LoginGUI = {};
local AlertGUI = {};

LoginGUI.window <- GUIWindow();
LoginGUI.window.setPosition(screen[0]/2-160, screen[1]/2-85, false);
LoginGUI.window.setSize(320.0, 180.0, false);
LoginGUI.window.setText("Вход");
LoginGUI.window.setVisible(false);

LoginGUI.welcometext <- GUIText();
LoginGUI.welcometext.setParent(LoginGUI.window.getName());
LoginGUI.welcometext.setPosition(20.0, 10.0, false);
LoginGUI.welcometext.setText("Здравствуйте!"); 
LoginGUI.welcometext.setProperty("Font", "calibri#5#1");
LoginGUI.welcometext.setVisible(true);

LoginGUI.logintext <- GUIText();
LoginGUI.logintext.setParent(LoginGUI.window.getName());
LoginGUI.logintext.setPosition(45.0, 40.0, false);
LoginGUI.logintext.setText("Логин: "); 
LoginGUI.logintext.setProperty("Font", "calibri#5#1");
LoginGUI.logintext.setVisible(true);

LoginGUI.passtext <- GUIText();
LoginGUI.passtext.setParent(LoginGUI.window.getName());
LoginGUI.passtext.setPosition(45.0, 70.0, false);
LoginGUI.passtext.setText("Пароль: "); 
LoginGUI.passtext.setProperty("Font", "calibri#5#1");
LoginGUI.passtext.setVisible(true);

LoginGUI.login <- GUIEditBox();
LoginGUI.login.setParent(LoginGUI.window.getName());
LoginGUI.login.setPosition(140.0, 40.0, false);
LoginGUI.login.setSize(160.0, 22.0, false);
LoginGUI.login.setProperty("MaskText", "false");
LoginGUI.login.setProperty("BlinkCaret", "true");
LoginGUI.login.setProperty("BlinkCaretTimeout", "1.0");
LoginGUI.login.setProperty("Font", "calibri");
LoginGUI.login.setProperty("SelectedTextColour", "FF0000FF");

LoginGUI.password <- GUIEditBox();
LoginGUI.password.setParent(LoginGUI.window.getName());
LoginGUI.password.setPosition(140.0, 70.0, false);
LoginGUI.password.setSize(160.0, 22.0, false);
LoginGUI.password.setProperty("MaskText", "true");
LoginGUI.password.setProperty("BlinkCaret", "true");
LoginGUI.password.setProperty("BlinkCaretTimeout", "1.0");
LoginGUI.password.setProperty("Font", "calibri");
LoginGUI.password.setProperty("SelectedTextColour", "FF0000FF");

LoginGUI.button <- GUIButton();
LoginGUI.button.setParent(LoginGUI.window.getName());
LoginGUI.button.setPosition(220.0, 110.0, false);
LoginGUI.button.setSize(80.0, 30.0, false);
LoginGUI.button.setText("ОК");
LoginGUI.button.setProperty("NormalTextColour", "FFFFFFFF");

LoginGUI.button2 <- GUIButton();
LoginGUI.button2.setParent(LoginGUI.window.getName());
LoginGUI.button2.setPosition(45.0, 110.0, false);
LoginGUI.button2.setSize(80.0, 30.0, false);
LoginGUI.button2.setText("Вход");
LoginGUI.button2.setProperty("NormalTextColour", "FFFFFFFF");
LoginGUI.button2.setVisible(true);/**/


function onAlert(title,button,body,show)
{
    AlertGUI.window <- GUIWindow();
	AlertGUI.window.setPosition(screen[0]/2-160, screen[1]/2-85, false);
	AlertGUI.window.setText(title);
	AlertGUI.window.setSize(320.0, 100.0, false);
	AlertGUI.window.setVisible(false);
	
	AlertGUI.bodytext <- GUIText();
	AlertGUI.bodytext.setParent(AlertGUI.window.getName());
	AlertGUI.bodytext.setPosition(20.0, 10.0, false);
	AlertGUI.bodytext.setText(body);
	AlertGUI.bodytext.setProperty("Font", "calibri#5#1");
	AlertGUI.bodytext.setVisible(true);
	
	AlertGUI.buttonOK <- GUIButton();
	AlertGUI.buttonOK.setParent(AlertGUI.window.getName());
	AlertGUI.buttonOK.setPosition(100.0, 30.0, false);
	AlertGUI.buttonOK.setSize(60.0, 30.0, false);
	AlertGUI.buttonOK.setText(button);
	AlertGUI.buttonOK.setProperty("NormalTextColour", "FFFFFFFF");
	
	if(show)
	{
	    AlertGUI.window.setVisible(true);
		guiToggleCursor(true);
	}
	else
	{
	    AlertGUI.window.setVisible(false);
		guiToggleCursor(false);
	}
}
addEvent("alert", onAlert);

function onShowLogin(show, login, hiddenCursor = false)
{
	guiToggleCursor(true);
	if(login)
	{
		LoginGUI.welcometext.setText("Введите свои данные для входа");
		LoginGUI.button.setText("Bxog");		
		LoginGUI.button2.setVisible(false);
		if(show == true)
		{
		    addChatMessage("По всем вопросам связанными с сервером, а так же разбаном",0xC0C0C0AA);
		    addChatMessage("обращайтесь на сайт сервера (форум): [00FF00AA]frs.ivmp.ru",0xC0C0C0AA,true);
		}
	}
	else
	{
		LoginGUI.welcometext.setText("Зарегестрируйтесь");
		LoginGUI.button.setText("Register");
		LoginGUI.button2.setVisible(true);
		if(show == true)
		{
		    addChatMessage("По всем вопросам связанными с сервером, а так же разбаном",0xC0C0C0AA);
		    addChatMessage("обращайтесь на сайт сервера (форум): [00FF00AA]frs.ivmp.ru",0xC0C0C0AA,true);
		}
	}
	if(show)
	{
		LoginGUI.window.setVisible(true);
	}
	else
	{
		LoginGUI.window.setVisible(false);
		callEvent("welcomMsg",false);
		if(hiddenCursor) guiToggleCursor(false);
	}

}
addEvent("showLogin", onShowLogin);

function onButtonClick(btnName, bState)
{
	switch(btnName)
	{
		case LoginGUI.button.getName():
			if(LoginGUI.button.getText() == "Bxog"){
				triggerServerEvent("playerLogin", LoginGUI.login.getText(), LoginGUI.password.getText(), true);
			} else {
				triggerServerEvent("playerLogin", LoginGUI.login.getText(), LoginGUI.password.getText(), false); 
			}
		break;
		case LoginGUI.button2.getName():
		    LoginGUI.welcometext.setText("Введите данные для входа          ");
			LoginGUI.button.setText("Bxog");
			LoginGUI.button2.setVisible(false);
		break;
		case AlertGUI.buttonOK.getName():
		    AlertGUI.window.setVisible(false);
			guiToggleCursor(true);
			LoginGUI.window.setVisible(true);
		break;
	}
}
addEvent("buttonClick", onButtonClick);