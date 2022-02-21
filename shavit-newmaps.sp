/* Header files */
#include <sourcemod>
#include <shavit/rankings>
#include <convar_class>

/* Preprocessor directives */
#pragma semicolon 1
#pragma newdecls required

/* Globals */
ArrayList gA_NewestMaps;

/* CVARs */
Convar gCV_MaxMapsToShow = null;

/* Plugin information */
public Plugin myinfo =
{
	name = "Recently uploaded maps",
	author = "Nairda",
	/* Thank you so much, Deadwinter */
	description = "Shows recently uploaded maps to the server.",
	url = "https://steamcommunity.com/id/nairda1339/"
};

enum struct MapInfo 
{
    int TimeStamp;
    char MapName[PLATFORM_MAX_PATH];
}

public void OnPluginStart()
{
  	gA_NewestMaps = new ArrayList(sizeof(MapInfo));
	RegConsoleCmd("sm_newmaps", NewestMaps, "List maps recently uploaded to the server. Sorting by date of upload.");
	
	gCV_MaxMapsToShow = new Convar("max_maps_to_show", "25", "How many maps to print in the menu?", 0, true, 1.0, true, 100.0);
	
	Convar.AutoExecConfig();
}

public Action NewestMaps(int client, int args) 
{
//	if(!IsValidClient(client))
//	{
//		return Plugin_Handled;
//	}

	UpdateMapsList();
	NewMapsMenu(client);

	return Plugin_Handled;
}

void NewMapsMenu(int client)
{
	Menu menu = new Menu(Handler_NewestMaps, MENU_ACTIONS_ALL);
	menu.SetTitle("New maps (Showing %i newest):\nTime | Map [Tier]", gCV_MaxMapsToShow.IntValue);

	int i_MapsCount = (gCV_MaxMapsToShow.IntValue < gA_NewestMaps.Length) ? gCV_MaxMapsToShow.IntValue : gA_NewestMaps.Length;

	for (int i = 0; i < i_MapsCount; i++)
	{
		MapInfo MapInfo_RecentUploads;
		gA_NewestMaps.GetArray(i, MapInfo_RecentUploads);

		int MapTier = Shavit_GetMapTier(MapInfo_RecentUploads.MapName);

		char TimeParsed[32];
		FormatTime(TimeParsed, 32, "%Y/%m/%d %H:%M", MapInfo_RecentUploads.TimeStamp);

		char Display[255];
		Format(Display, 255, "%s | %s [T%i]", TimeParsed, MapInfo_RecentUploads.MapName, MapTier);

		menu.AddItem(MapInfo_RecentUploads.MapName, Display);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_NewestMaps(Menu menu, MenuAction action, int client, int choice)
{
	if(action == MenuAction_Select)
	{
		char Handler_MapName[256];
		menu.GetItem(choice, Handler_MapName, 256);

		FakeClientCommand(client, "sm_nominate %s", Handler_MapName);
		
		// I really am fucking retarded apparently. 
		// Thank you Bara for noticing. 
		// Thank you .sneaK for pushing me to examine. 
		// Thank you GAMMACASE for being patient yet again and explaining stuff to me like you were dealing with a retard, which you apparently have.
		NewMapsMenu(client);

	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

stock void UpdateMapsList()
{
	gA_NewestMaps.Clear();

	char path[PLATFORM_MAX_PATH];
	Handle dir = OpenDirectory("maps/");

	if(dir != INVALID_HANDLE)
	{
		char MapName[PLATFORM_MAX_PATH];
		FileType type; 
		while (ReadDirEntry(dir, MapName, PLATFORM_MAX_PATH, type))
		{
			if(type == FileType_File && StrContains(MapName, ".bsp", false) != -1) 
			{
				Format(path, PLATFORM_MAX_PATH, "%s/%s", "maps", MapName);
				MapInfo MapInfo_RecentUploads;
				ReplaceString(MapName, PLATFORM_MAX_PATH, ".bsp", "", false);
				MapInfo_RecentUploads.MapName = MapName;
				MapInfo_RecentUploads.TimeStamp = GetFileTime(path, FileTime_LastChange);

				gA_NewestMaps.PushArray(MapInfo_RecentUploads);
			}
		}

		CloseHandle(dir);
	}
	else
	{
		PrintToServer("Failed to open the /maps directory.");
	}
	
	gA_NewestMaps.Sort(Sort_Descending, Sort_Integer);
}
