#define GIVE_CREDITS	0
#define TAKE_CREDITS	1
#define SET_CREDITS		2
#define GIVE_ITEMS		3
#define TAKE_ITEMS		4
#if defined SHOP_CORE_PREMIUM
#define GIVE_GOLD	5
#define TAKE_GOLD	6
#define SET_GOLD	7
#endif

enum struct AdminEnum
{
	int AdminOption;
	int AdminTarget;
	int AdminCategory;
}

AdminEnum g_iOpt[MAXPLAYERS+1];

Menu count_menu;
#if defined SHOP_CORE_PREMIUM
Menu gold_count_menu;
#endif

/**
 * For SM 1.10
 */
stock DataPackPos ADMIN_DP_PLUGIN			= view_as<DataPackPos>(0);
stock DataPackPos ADMIN_DP_FUNCDISPLAY	= view_as<DataPackPos>(1);
stock DataPackPos ADMIN_DP_FUNCSELECT		= view_as<DataPackPos>(2);

ArrayList g_hAdminArray;

void Admin_CreateNatives()
{
	g_hAdminArray = new ArrayList(3);

	CreateNative("Shop_AddToAdminMenu", Admin_AddToMenuNative);
	CreateNative("Shop_RemoveFromAdminMenu", Admin_RemoveFromMenuNative);
	CreateNative("Shop_ShowAdminMenu", Admin_ShowAdminMenu);
}

public int Admin_AddToMenuNative(Handle plugin, int numParams)
{
	DataPack dp = new DataPack();
	dp.WriteCell(plugin);
	dp.WriteFunction(GetNativeFunction(1));
	dp.WriteFunction(GetNativeFunction(2));

	g_hAdminArray.Push(plugin);
	g_hAdminArray.Push(dp);
}

public int Admin_RemoveFromMenuNative(Handle plugin, int numParams)
{
	int index = -1;
	DataPack dp;
	while ((index = g_hAdminArray.FindValue(plugin)) != -1)
	{
		dp = g_hAdminArray.Get(index+1);
		dp.Position = ADMIN_DP_FUNCDISPLAY; // jump to func display
		Function func_disp = dp.ReadFunction();
		Function func_select = dp.ReadFunction();
		if (func_disp == GetNativeFunction(1) && func_select == GetNativeFunction(2))
		{
			// double action to delete Handle (plugin) and datapack (plugin, func_disp, func_select)
			g_hAdminArray.Erase(index);
			g_hAdminArray.Erase(index);

			delete dp;
			return true;
		}
	}

	return false;
}

public int Admin_ShowAdminMenu(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	char error[64];
	if (!CheckClient(client, error, sizeof(error)))
		ThrowNativeError(SP_ERROR_NATIVE, error);

	Admin_ShowMenu(client);
}

void Admin_UnregisterMe(Handle hPlugin)
{
	int index = -1;
	while ((index = g_hAdminArray.FindValue(hPlugin)) != -1)
	{
		delete view_as<Handle>(g_hAdminArray.Get(index+1));

		g_hAdminArray.Erase(index);
		g_hAdminArray.Erase(index);
	}
}

void Admin_OnSettingsLoad(KeyValues kv)
{
	count_menu = new Menu(Admin_MenuCount_Handler, MENU_ACTIONS_DEFAULT|MenuAction_Display);

	if (kv.JumpToKey("Count_Menu", false))
	{
		if (kv.GotoFirstSubKey(false))
		{
			char amount[24], buffer[64];
			do
			{
				if (kv.GetSectionName(amount, sizeof(amount)))
				{
					kv.GetString(NULL_STRING, buffer, sizeof(buffer));
					if (amount[0] && buffer[0])
					{
						count_menu.AddItem(amount, buffer);
					}
				}
			}
			while (kv.GotoNextKey(false));
		}
		kv.Rewind();
	}

	if (!count_menu.ItemCount)
	{
		count_menu.AddItem("1", "1 credit");
		count_menu.AddItem("10", "10 credits");
		count_menu.AddItem("100", "Hundred credits");
		count_menu.AddItem("1000", "Thousand credits");
		count_menu.AddItem("10000", "10000 credits");
		count_menu.AddItem("100000", "100000 credits");
		count_menu.AddItem("1000000", "Million credits");
	}

	count_menu.ExitButton = true;
	count_menu.ExitBackButton = true;

#if defined SHOP_CORE_PREMIUM
	gold_count_menu = new Menu(Admin_MenuCount_Handler, MENU_ACTIONS_DEFAULT|MenuAction_Display);

	if (kv.JumpToKey("Gold_Count_Menu", false) || kv.JumpToKey("Count_Menu", false))
	{
		if (kv.GotoFirstSubKey(false))
		{
			char amount[24], buffer[64];
			do
			{
				if (kv.GetSectionName(amount, sizeof(amount)))
				{
					kv.GetString(NULL_STRING, buffer, sizeof(buffer));
					if (amount[0] && buffer[0])
					{
						gold_count_menu.AddItem(amount, buffer);
					}
				}
			}
			while (kv.GotoNextKey(false));
		}
		kv.Rewind();
	}

	if (!gold_count_menu.ItemCount)
	{
		gold_count_menu.AddItem("1", "1 gold");
		gold_count_menu.AddItem("10", "10 golds");
		gold_count_menu.AddItem("100", "Hundred golds");
		gold_count_menu.AddItem("1000", "Thousand golds");
		gold_count_menu.AddItem("10000", "10000 golds");
		gold_count_menu.AddItem("100000", "100000 golds");
		gold_count_menu.AddItem("1000000", "Million golds");
	}

	gold_count_menu.ExitButton = true;
	gold_count_menu.ExitBackButton = true;
#endif
}

public int Admin_MenuCount_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Display :
		{
			int target = GetClientOfUserId(g_iOpt[param1].AdminTarget);

			if (!target)
			{
				return;
			}

			switch (g_iOpt[param1].AdminOption)
			{
				case GIVE_CREDITS :
				{
					menu.SetTitle("%T\n%N (%d)\n ", "give_credits", param1, target, GetCredits(target));
				}
				case TAKE_CREDITS :
				{
					menu.SetTitle("%T\n%N (%d)\n ", "take_credits", param1, target, GetCredits(target));
				}
				case SET_CREDITS :
				{
					menu.SetTitle("%T\n%N (%d)\n ", "set_credits", param1, target, GetCredits(target));
				}
#if defined SHOP_CORE_PREMIUM
				case GIVE_GOLD :
				{
					menu.SetTitle("%T\n%N (%d)\n ", "give_gold", param1, target, GetGold(target));
				}
				case TAKE_GOLD :
				{
					menu.SetTitle("%T\n%N (%d)\n ", "take_gold", param1, target, GetGold(target));
				}
				case SET_GOLD :
				{
					menu.SetTitle("%T\n%N (%d)\n ", "set_gold", param1, target, GetGold(target));
				}
#endif
			}
		}
		case MenuAction_Select :
		{
			int target = GetClientOfUserId(g_iOpt[param1].AdminTarget);

			if (!target)
			{
				CPrintToChat(param1, "%t", "target_left_game");
				Admin_ShowMenu(param1);
				return;
			}

			char info[16];
			menu.GetItem(param2, info, sizeof(info));

			switch (g_iOpt[param1].AdminOption)
			{
				case GIVE_CREDITS :
				{
					GiveCredits(target, StringToInt(info), param1);
					Admin_ShowCreditsAmount(param1, GetMenuSelectionPosition());
				}
				case TAKE_CREDITS :
				{
					RemoveCredits(target, StringToInt(info), param1);
					Admin_ShowCreditsAmount(param1, GetMenuSelectionPosition());
				}
				case SET_CREDITS :
				{
					SetCredits(target, StringToInt(info), param1);
					Admin_ShowMenu(param1);
				}
#if defined SHOP_CORE_PREMIUM
				case GIVE_GOLD :
				{
					GiveGold(target, StringToInt(info), param1);
					Admin_ShowGoldAmount(param1, GetMenuSelectionPosition());
				}
				case TAKE_GOLD :
				{
					RemoveGold(target, StringToInt(info), param1);
					Admin_ShowGoldAmount(param1, GetMenuSelectionPosition());
				}
				case SET_GOLD :
				{
					SetGold(target, StringToInt(info), param1);
					Admin_ShowMenu(param1);
				}
#endif
			}
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Admin_ShowTargetsMenu(param1);
			}
		}
	}
}

void Admin_ShowMenu(int client, int pos = 0)
{
	SetGlobalTransTarget(client);

	Menu menu = new Menu(Admin_Menu_Handler);

	char title[128];
	FormatEx(title, sizeof(title), "%t", "admin_panel");
	OnMenuTitle(client, Menu_AdminPanel, title, title, sizeof(title));
	menu.SetTitle(title);
	menu.ExitButton = true;
	menu.ExitBackButton = true;

	char buffer[SHOP_MAX_STRING_LENGTH];
	FormatEx(buffer, sizeof(buffer), "%t", "give_credits");
	menu.AddItem("a", buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "take_credits");
	menu.AddItem("b", buffer);
	FormatEx(buffer, sizeof(buffer), "%t\n ", "set_credits");
	menu.AddItem("c", buffer);
#if defined SHOP_CORE_PREMIUM
	FormatEx(buffer, sizeof(buffer), "%t", "give_gold");
	menu.AddItem("f", buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "take_gold");
	menu.AddItem("g", buffer);
	FormatEx(buffer, sizeof(buffer), "%t\n ", "set_gold");
	menu.AddItem("h", buffer);
#endif
	FormatEx(buffer, sizeof(buffer), "%t", "give_items");
	menu.AddItem("d", buffer);
	FormatEx(buffer, sizeof(buffer), "%t", "take_items");
	menu.AddItem("e", buffer);

	int size = g_hAdminArray.Length;

	if (size > 0)
	{
		DataPack dp;
		char id[16], display[64];

		for (int i = 1; i < size; i+=2)
		{
			dp = g_hAdminArray.Get(i);

			dp.Reset();
			Handle plugin = dp.ReadCell();
			Function func_disp = dp.ReadFunction();

			display[0] = 0;
			if (IsCallValid(plugin, func_disp)) {
				Call_StartFunction(plugin, func_disp);
				Call_PushCell(client);
				Call_PushStringEx(display, sizeof(display), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCell(sizeof(display));
				Call_Finish();
			}

			if (!display[0])
				continue;

			IntToString(i, id, sizeof(id));

			menu.AddItem(id, display);
		}
	}

	menu.DisplayAt(client, pos, MENU_TIME_FOREVER);
}

public int Admin_Menu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));

			switch (info[0])
			{
				case 'a' :
				{
					g_iOpt[param1].AdminOption = GIVE_CREDITS;
				}
				case 'b' :
				{
					g_iOpt[param1].AdminOption = TAKE_CREDITS;
				}
				case 'c' :
				{
					g_iOpt[param1].AdminOption = SET_CREDITS;
				}
				case 'd' :
				{
					g_iOpt[param1].AdminOption = GIVE_ITEMS;
				}
				case 'e' :
				{
					g_iOpt[param1].AdminOption = TAKE_ITEMS;
				}
#if defined SHOP_CORE_PREMIUM
				case 'f' :
				{
					g_iOpt[param1].AdminOption = GIVE_GOLD;
				}
				case 'g' :
				{
					g_iOpt[param1].AdminOption = TAKE_GOLD;
				}
				case 'h' :
				{
					g_iOpt[param1].AdminOption = SET_GOLD;
				}
#endif
				default :
				{
					bool result = false;

					DataPack dp;
					dp = g_hAdminArray.Get(StringToInt(info));
					if (dp != null)
					{
						dp.Reset();
						Handle plugin = dp.ReadCell();

						dp.Position = ADMIN_DP_FUNCSELECT; // Skip func_diplay
						Function func_select = dp.ReadFunction();

						if (IsCallValid(plugin, func_select)) {
							Call_StartFunction(plugin, func_select);
							Call_PushCell(param1);
							Call_Finish(result);
						}
					}

					if (!result)
						Admin_ShowMenu(param1, GetMenuSelectionPosition());

					return;
				}
			}

			if (!Admin_ShowTargetsMenu(param1))
			{
				CPrintToChat(param1, "no_targets");
				Admin_ShowMenu(param1, GetMenuSelectionPosition());
			}
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				ShowMainMenu(param1);
			}
		}
		case MenuAction_End :
		{
			delete menu;
		}
	}
}

bool Admin_ShowTargetsMenu(int client, int pos = 0)
{
	SetGlobalTransTarget(client);

	Menu menu = new Menu(Admin_TargetsMenu_Handler);
	if (!AddTargetsToMenu(menu, client, (g_iOpt[client].AdminOption != GIVE_ITEMS && g_iOpt[client].AdminOption != TAKE_ITEMS)))
	{
		delete menu;
		return false;
	}

	menu.SetTitle("%t\n ", "select_target");
	menu.ExitButton = true;
	menu.ExitBackButton = true;

	menu.DisplayAt(client, pos, MENU_TIME_FOREVER);

	return true;
}

public int Admin_TargetsMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));

			int userid = StringToInt(info);
			int target = GetClientOfUserId(userid);

			if (!target)
			{
				CPrintToChat(param1, "%t", "target_left_game");
				Admin_ShowTargetsMenu(param1, GetMenuSelectionPosition());
				return;
			}

			g_iOpt[param1].AdminTarget = userid;

			switch (g_iOpt[param1].AdminOption)
			{
				case GIVE_CREDITS, TAKE_CREDITS, SET_CREDITS :
				{
					Admin_ShowCreditsAmount(param1);
				}
#if defined SHOP_CORE_PREMIUM
				case GIVE_GOLD, TAKE_GOLD, SET_GOLD :
				{
					Admin_ShowGoldAmount(param1);
				}
#endif
				case GIVE_ITEMS, TAKE_ITEMS :
				{
					Admin_ShowCategories(param1);
				}
			}
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Admin_ShowMenu(param1);
			}
		}
		case MenuAction_End :
		{
			delete menu;
		}
	}
}

void Admin_ShowCreditsAmount(int client, int pos = 0)
{
	count_menu.DisplayAt(client, pos, MENU_TIME_FOREVER);
}

#if defined SHOP_CORE_PREMIUM
void Admin_ShowGoldAmount(int client, int pos = 0)
{
	gold_count_menu.DisplayAt(client, pos, MENU_TIME_FOREVER);
}
#endif

bool Admin_ShowCategories(int client, int pos = 0)
{
	SetGlobalTransTarget(client);

	Menu menu = new Menu(Admin_CategoriesMenu_Handler);
	if (!FillCategories(menu, client, false, true))
	{
		CPrintToChat(client, "%t", "EmptyShop");
		delete menu;
		return false;
	}

	menu.SetTitle("%t\n ", "select_category");
	menu.ExitButton = true;
	menu.ExitBackButton = true;

	menu.DisplayAt(client, pos, MENU_TIME_FOREVER);

	return true;
}

public int Admin_CategoriesMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select :
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));

			int target = GetClientOfUserId(g_iOpt[param1].AdminTarget);

			if (!target)
			{
				CPrintToChat(param1, "%t", "target_left_game");
				Admin_ShowTargetsMenu(param1, GetMenuSelectionPosition());
				return;
			}

			g_iOpt[param1].AdminCategory = StringToInt(info);

			Admin_ShowItemsOfCategory(param1, g_iOpt[param1].AdminCategory);
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Admin_ShowTargetsMenu(param1);
			}
		}
		case MenuAction_End :
		{
			delete menu;
		}
	}
}

bool Admin_ShowItemsOfCategory(int client, int category_id, int pos = 0)
{
	SetGlobalTransTarget(client);

	Menu menu = new Menu(Admin_ItemsMenu_Handler, MENU_ACTIONS_DEFAULT|MenuAction_Display|MenuAction_DrawItem|MenuAction_DisplayItem);
	if (!FillItemsOfCategory(menu, client, client, category_id, true))
	{
		CPrintToChat(client, "%t", "EmptyCategory");
		delete menu;
		return false;
	}

	menu.ExitButton = true;
	menu.ExitBackButton = true;

	menu.DisplayAt(client, pos, MENU_TIME_FOREVER);

	return true;
}

public int Admin_ItemsMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Display :
		{
			switch (g_iOpt[param1].AdminOption)
			{
				case GIVE_ITEMS :
				{
					menu.SetTitle("%t\n ", "give_items");
				}
				case TAKE_ITEMS :
				{
					menu.SetTitle("%t\n ", "take_items");
				}
			}
		}
		case MenuAction_DrawItem  :
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));

			int target = GetClientOfUserId(g_iOpt[param1].AdminTarget);

			ItemType type = GetItemTypeEx(info);

			if (type != Item_Finite && type != Item_BuyOnly)
			{
				switch (g_iOpt[param1].AdminOption)
				{
					case GIVE_ITEMS :
					{
						if (ClientHasItemEx(target, info))
						{
							return ITEMDRAW_DISABLED;
						}
					}
					case TAKE_ITEMS :
					{
						if (!ClientHasItemEx(target, info))
						{
							return ITEMDRAW_DISABLED;
						}
					}
				}
			}
		}
		case MenuAction_DisplayItem :
		{
			char info[16], buffer[SHOP_MAX_STRING_LENGTH];
			menu.GetItem(param2, info, sizeof(info), _, buffer, sizeof(buffer));

			ItemType type = GetItemTypeEx(info);

			if (type == Item_BuyOnly)
			{
				return 0;
			}

			int target = GetClientOfUserId(g_iOpt[param1].AdminTarget);

			if (type == Item_Finite)
			{
				Format(buffer, sizeof(buffer), "%s (%d)", buffer, GetItemCountEx(target, info));
				return RedrawMenuItem(buffer);
			}
			switch (g_iOpt[param1].AdminOption)
			{
				case GIVE_ITEMS :
				{
					if (ClientHasItemEx(target, info))
					{
						Format(buffer, sizeof(buffer), "[+] %s", buffer);
						return RedrawMenuItem(buffer);
					}
				}
				case TAKE_ITEMS :
				{
					if (!ClientHasItemEx(target, info))
					{
						Format(buffer, sizeof(buffer), "[-] %s", buffer);
						return RedrawMenuItem(buffer);
					}
				}
			}
		}
		case MenuAction_Select :
		{
			char info[16];
			menu.GetItem(param2, info, sizeof(info));

			int target = GetClientOfUserId(g_iOpt[param1].AdminTarget);

			if (!target)
			{
				CPrintToChat(param1, "%t", "target_left_game");
				Admin_ShowMenu(param1);
				return 0;
			}

			switch (g_iOpt[param1].AdminOption)
			{
				case GIVE_ITEMS :
				{
					if (GiveItemEx(target, info))
					{
						CPrintToChat(param1, "%t", "give_item_success");
					}
				}
				case TAKE_ITEMS :
				{
					if (RemoveItemEx(target, info, (GetItemTypeEx(info) == Item_Finite) ? 1 : -1))
					{
						CPrintToChat(param1, "%t", "take_item_success");
					}
				}
			}

			Admin_ShowItemsOfCategory(param1, g_iOpt[param1].AdminCategory, GetMenuSelectionPosition());
		}
		case MenuAction_Cancel :
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Admin_ShowCategories(param1);
			}
		}
		case MenuAction_End :
		{
			delete menu;
		}
	}

	return 0;
}

stock bool HasFlags(int client, char[] sFlags)
{
	if (StrEqual(sFlags, "public", false) || StrEqual(sFlags, "", false))
	{
		return true;
	}

	if (StrEqual(sFlags, "none", false))
	{
		return false;
	}

	AdminId id = GetUserAdmin(client);
	if (id == INVALID_ADMIN_ID)
	{
		return false;
	}

	int iCount, iFound, flags;
	if (StrContains(sFlags, ";", false) != -1) //check if multiple strings
	{
		int c = 0, iStrCount = 0;
		while (sFlags[c] != '\0')
		{
			if (sFlags[c++] == ';')
			{
				iStrCount++;
			}
		}
		iStrCount++; //add one more for IP after last comma
		char[][] sTempArray = new char[iStrCount][32];
		ExplodeString(sFlags, ";", sTempArray, iStrCount, 32);

		for (int i = 0; i < iStrCount; i++)
		{
			if (strncmp(sTempArray[i], "STEAM_", 6) == 0)
			{
				char sSteam32ID[32];
				GetClientAuthId(client, AuthId_Steam2, sSteam32ID, sizeof(sSteam32ID));
				if (StrEqual(sTempArray[i][8], sSteam32ID[8]))
				{
					return true;
				}

				continue;
			}

			flags = ReadFlagString(sTempArray[i]);
			iCount = 0;
			iFound = 0;
			for (int j = 0; j <= 20; j++)
			{
				if (flags & (1<<j))
				{
					iCount++;

					if (GetAdminFlag(id, view_as<AdminFlag>(j)))
					{
						iFound++;
					}
				}
			}

			if (iCount == iFound)
			{
				return true;
			}
		}
	}
	else
	{
		if (strncmp(sFlags, "STEAM_", 6) == 0)
		{
			char sSteam32ID[32];
			GetClientAuthId(client, AuthId_Steam2, sSteam32ID, sizeof(sSteam32ID));
			if (StrEqual(sFlags[8], sSteam32ID[8]))
			{
				return true;
			}

			return false;
		}

		flags = ReadFlagString(sFlags);
		iCount = 0;
		iFound = 0;
		for (int i = 0; i <= 20; i++)
		{
			if (flags & (1<<i))
			{
				iCount++;

				if (GetAdminFlag(id, view_as<AdminFlag>(i)))
				{
					iFound++;
				}
			}
		}

		if (iCount == iFound)
		{
			return true;
		}
	}
	return false;
}
