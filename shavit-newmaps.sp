#include <shavit>
 
public void OnPluginStart()
{
	RegConsoleCmd("sm_newmaps", Command_AddedMaps);
	RegConsoleCmd("sm_nm", Command_AddedMaps);
	RegConsoleCmd("sm_newmapsm", Command_AddedMaps_Main);
	RegConsoleCmd("sm_nmm", Command_AddedMaps_Main);
	RegConsoleCmd("sm_newmapb", Command_AddedMaps_Bonus);
	RegConsoleCmd("sm_nmb", Command_AddedMaps_Bonus);
}
 
public Action Command_AddedMaps(int client, int args)
{
	SelectTrackMenu(client);
	return Plugin_Handled;
}
 
public Action Command_AddedMaps_Main(int client, int args)
{
	BuildMenu(client, 0);
	return Plugin_Handled;
}
 
public Action Command_AddedMaps_Bonus(int client, int args)
{
	BuildMenu(client, 1);
	return Plugin_Handled;
}
 
SelectTrackMenu(client)
{
	Menu menu = new Menu(Handler_SelectTrack);
	menu.SetTitle("Select a track");
	
	menu.AddItem("0", "Main");
	menu.AddItem("1", "Bonus");
 
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}
 
public int Handler_SelectTrack(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{		
		char sType[2];
		GetMenuItem(menu, param2, sType, sizeof(sType));
		BuildMenu(client, StringToInt(sType));
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
 
	return 0;
}
 
BuildMenu(client, type)
{
	char sQuery[256];
	FormatEx(sQuery, sizeof(sQuery), "SELECT distinct map from `mapzones`WHERE `track`=%d AND `type`<=1 ORDER BY `id` DESC LIMIT 50;", type);
	SQL_TQuery(Shavit_GetDatabase(), SQL_GetMaps, sQuery, GetClientUserId(client), DBPrio_Normal);
}
 
public void SQL_GetMaps(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == null)
	{
		LogError("Timer error! Failed to build recently added maps menu!. Reason: %s", error);
		return;
	}
 
	int client = GetClientOfUserId(data);
	
	Menu menu = new Menu(Handler_RecentMaps);
	menu.SetTitle("Recently Added Maps");
	
	char sMap[128];
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, sMap, sizeof(sMap));
		menu.AddItem(sMap, sMap);
	}
 
	menu.ExitButton = true;
	SetMenuExitBackButton(menu, true);
	menu.Display(client, MENU_TIME_FOREVER);
}
 
public int Handler_RecentMaps(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{		
		char sMap[64];
		GetMenuItem(menu, param2, sMap, sizeof(sMap));
		FakeClientCommand(client, "sm_nominate %s", sMap);
	}
	else if (action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
			SelectTrackMenu(client);
	}
	if(action == MenuAction_End)
	{
		delete menu;
	}
 
	return 0;
}
