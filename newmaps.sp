/* Header files */
#include <sourcemod>
#include <shavit>

/* Preprocessor directives */
#pragma semicolon 1
#pragma newdecls required

#define MAX_MAPS_TO_SHOW 15 // Placeholder, gonna add a .cfg


/* Globals */
ArrayList gA_NewestMaps;

/* Plugin information */
public Plugin myinfo =
{
	name = "NewMaps",
	author = "Nairda",
	/* Thank you so much, Deadwinter, for all your help with Pawn and teaching me. Your patience with my stupidity is insane. Big love. */
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
	RegConsoleCmd("sm_newmaps", NewestMaps, "List maps recently uploaded to the server. Sorted by date of upload.");
}

public Action NewestMaps(int client, int args) 
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	UpdateMapsList();
	NewMapsMenu(client);

	return Plugin_Handled;
}

void NewMapsMenu(int client)
{
	Menu g_NewestMapsMenu = new Menu(Handler_NewestMaps, MENU_ACTIONS_ALL);
	g_NewestMapsMenu.SetTitle("New maps:");

	int i_MapsCount = (MAX_MAPS_TO_SHOW < gA_NewestMaps.Length) ? MAX_MAPS_TO_SHOW : gA_NewestMaps.Length;

	for (int i = 0; i < i_MapsCount; i++)
	{
		MapInfo MapInfo_RecentUploads;
		gA_NewestMaps.GetArray(i, MapInfo_RecentUploads);

		int MapTier = Shavit_GetMapTier(MapInfo_RecentUploads.MapName);

		char TimeParsed[32];
		FormatTime(TimeParsed, 32, "%Y/%m/%d %H:%M", MapInfo_RecentUploads.TimeStamp);

		char Display[255];
		Format(Display, 255, "%s | %s [T%i]", TimeParsed, MapInfo_RecentUploads.MapName, MapTier);

		g_NewestMapsMenu.AddItem(MapInfo_RecentUploads.MapName, Display);
	}

	g_NewestMapsMenu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_NewestMaps(Menu g_NewestMapsMenu, MenuAction action, int client, int choice)
{
	if(action == MenuAction_Select)
	{
		char Handler_MapName[256];
		g_NewestMapsMenu.GetItem(choice, Handler_MapName, 256);

		FakeClientCommand(client, "sm_nominate %s", Handler_MapName);

		g_NewestMapsMenu.Display(client, MENU_TIME_FOREVER);
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
		PrintToServer("Failed to open dir");
	}
	
	gA_NewestMaps.Sort(Sort_Descending, Sort_Integer);
}
