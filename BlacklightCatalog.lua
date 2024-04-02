-- We will store the interface manager object here so that we don't have to make multiple GetInterfaceManager calls.
local interfaceMngr = nil;

-- The CatalogForm table allows us to store all objects related to the specific form inside the table so that we can easily prevent naming conflicts if we need to add more than one form and track elements from both.
local CatalogForm = {};
CatalogForm.Form = nil;
CatalogForm.RibbonPage = nil;
CatalogForm.Browser = nil;
CatalogForm.RetrieveButton = nil;
CatalogForm.ImportButton = nil;
CatalogForm.SearchButtons = {};
CatalogForm.SearchButtons.Advanced = nil;
CatalogForm.SearchButtons.Title = nil;
CatalogForm.SearchButtons.ISxN = nil;
CatalogForm.SearchButtons.Barcode = nil;
CatalogForm.SearchButtons.CallNumber = nil;
CatalogForm.EResourceLinkButton = nil;

luanet.load_assembly("System");
luanet.load_assembly("System.Xml");
luanet.load_assembly("System.Data");
luanet.load_assembly("System.Drawing");
luanet.load_assembly("System.Windows.Forms");
luanet.load_assembly("DevExpress.XtraBars");
luanet.load_assembly("DevExpress.XtraGrid");
luanet.load_assembly("log4net");

local Types = {};
Types["System.Data.DataTable"] = luanet.import_type("System.Data.DataTable");
Types["System.Drawing.Size"] = luanet.import_type("System.Drawing.Size");
Types["DevExpress.XtraBars.BarShortcut"] = luanet.import_type("DevExpress.XtraBars.BarShortcut");
Types["DevExpress.XtraGrid.Views.Grid.ViewInfo.GridHitTest"] = luanet.import_type("DevExpress.XtraGrid.Views.Grid.ViewInfo.GridHitTest")
Types["System.Windows.Forms.Shortcut"] = luanet.import_type("System.Windows.Forms.Shortcut");
Types["System.Windows.Forms.Keys"] = luanet.import_type("System.Windows.Forms.Keys");
Types["System.Diagnostics.Process"] = luanet.import_type("System.Diagnostics.Process");
Types["System.DBNull"] = luanet.import_type("System.DBNull");
Types["System.Net.WebClient"] = luanet.import_type("System.Net.WebClient");
Types["System.Net.WebUtility"] = luanet.import_type("System.Net.WebUtility");
Types["System.Text.Encoding"] = luanet.import_type("System.Text.Encoding");
Types["log4net.LogManager"] = luanet.import_type("log4net.LogManager");
Types["System.Windows.Forms.Cursor"] = luanet.import_type("System.Windows.Forms.Cursor");
Types["System.Xml.XmlDocument"] = luanet.import_type("System.Xml.XmlDocument");

local log = Types["log4net.LogManager"].GetLogger("AtlasSystems.Addons.BlacklightCatalog");

require "AtlasHelpers";
require "DataMapping";

-- Retrieve our settings and store them in local variables to prevent redundant fetching of settings. The creation of a table is not necessary, but like the form table above, it makes prevention of naming conflicts easier.
local Settings = {}
Settings.BaseUrl = GetSetting("BaseUrl");
Settings.AdvancedSearchUrl = GetSetting("AdvancedSearchUrl");
Settings.SearchPriority = AtlasHelpers.StringSplit(",", GetSetting("SearchPriority"));
Settings.AutoSearch = GetSetting("AutoSearch");
Settings.AutoRetrieveItems = GetSetting("AutoRetrieveItems");
Settings.KeepOriginalIsxn = GetSetting("KeepOriginalIsxn");
Settings.EResourceIndicator = GetSetting("EResourceIndicator");
Settings.EResourceLinkField = GetSetting("EResourceLinkField");
Settings.CombinedImportFields = AtlasHelpers.StringSplit(",", GetSetting("CombinedImportFields"));
Settings.ImportEntireWorkPages = GetSetting("ImportEntireWorkPages");
Settings.DisplayInvalidSearchMessage = GetSetting("DisplayInvalidSearchMessage");
Settings.RemoveTrailingSpecialCharacters = GetSetting("RemoveTrailingSpecialCharacters");

local isEResource = false;
local xmlRecordsCache = {};
local itemsGridControl;
local itemsGridView;
local browserType;

function Init()
	interfaceMngr = GetInterfaceManager();
	
	-- Create a form
	CatalogForm.Form = interfaceMngr:CreateForm("Blacklight", "Script");
	
	-- Add a browser
	if AddonInfo.Browsers and AddonInfo.Browsers.WebView2 then
		browserType = "WebView2";
	else
		browserType = "Chromium";
	end
	CatalogForm.Browser = CatalogForm.Form:CreateBrowser("Catalog", "Catalog", "Catalog", browserType);
	
	-- Hide the text label
	CatalogForm.Browser.TextSize = Types["System.Drawing.Size"].Empty;
	CatalogForm.Browser.TextVisible = false;
	
	-- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method. We can retrieve that one and add our buttons to it.
	CatalogForm.RibbonPage = CatalogForm.Form:GetRibbonPage("Catalog");
	
	-- Create the search and import buttons. We are storing the import button so we can enable it and disable it as needed.
	CatalogForm.SearchButtons.Advanced = CatalogForm.RibbonPage:CreateButton("Advanced Search", GetClientImage(HostAppInfo.Icons["AdvancedSearch"]), "GoToAdvanced", "Search");
	CatalogForm.SearchButtons.Title = CatalogForm.RibbonPage:CreateButton("Title", GetClientImage(HostAppInfo.Icons["TitleSearch"]), "ManualSearchTitle", "Search");
	CatalogForm.SearchButtons.ISxN = CatalogForm.RibbonPage:CreateButton("ISxN", GetClientImage(HostAppInfo.Icons["ISxNSearch"]), "ManualSearchIsxn", "Search");
	CatalogForm.SearchButtons.Barcode = CatalogForm.RibbonPage:CreateButton("Barcode", GetClientImage(HostAppInfo.Icons["BarcodeSearch"]), "ManualSearchBarcode", "Search");
	CatalogForm.SearchButtons.CallNumber = CatalogForm.RibbonPage:CreateButton("Call Number", GetClientImage(HostAppInfo.Icons["CallNumberSearch"]), "ManualCallNumberSearch", "Search");
	
	if not Settings.AutoRetrieveItems then
		CatalogForm.RetrieveButton = CatalogForm.RibbonPage:CreateButton("Retrieve Items", GetClientImage(HostAppInfo.Icons["RetrieveItems"]), "RetrieveItems", "Import");
		CatalogForm.RetrieveButton.BarButton.Enabled = false;
	end
	
	CatalogForm.ImportButton = CatalogForm.RibbonPage:CreateButton("Import", GetClientImage(HostAppInfo.Icons["Import"]), "DoItemImport", "Import");
	CatalogForm.ImportButton.BarButton.ItemShortcut = Types["DevExpress.XtraBars.BarShortcut"](Types["System.Windows.Forms.Shortcut"].CtrlI);
	CatalogForm.ImportButton.BarButton.Enabled = false;

	CatalogForm.EResourceLinkButton = CatalogForm.RibbonPage:CreateButton("Open Electronic Resource", GetClientImage(HostAppInfo.Icons["EResourceLink"]), "OpenEResourceLink", "Tools");
	CatalogForm.EResourceLinkButton.BarButton.Enabled = false;
	
	BuildBibGrid();
	BuildItemsGrid();
	
	CatalogForm.Form:LoadLayout("layout" .. browserType .. ".xml");
	
	-- After we add all of our buttons and form elements, we can show the form.
	CatalogForm.Form:Show();

	RegisterItemPageHandler();
	RegisterLocateRequestItemHandler();
	
	if Settings.AutoSearch then
		AutoSearch();
	else
		GoToAdvanced();
	end
	
end

function GoToAdvanced()
	CatalogForm.Browser:Navigate(Settings.AdvancedSearchUrl);
end

function ManualSearchIsxn()
	if not TrySearch("isxn") and Settings.DisplayInvalidSearchMessage then
		interfaceMngr:ShowMessage("The search could not be completed because no ISxN is present in the request.", "Search Failed");
	end
end

function ManualSearchTitle()
	if not TrySearch("title") and Settings.DisplayInvalidSearchMessage then
		interfaceMngr:ShowMessage("The search could not be completed because no title is present in the request.", "Search Failed");
	end
end

function ManualSearchBarcode()
	if not TrySearch("barcode") and Settings.DisplayInvalidSearchMessage then
		interfaceMngr:ShowMessage("The search could not be completed because no barcode is present in the request.", "Search Failed");
	end
end

function ManualCallNumberSearch()
	if not TrySearch("callnumber") and Settings.DisplayInvalidSearchMessage then
		interfaceMngr:ShowMessage("The search could not be completed because no call number is present in the request.", "Search Failed");
	end
end

function AutoSearch()
	local priorityList = Settings.SearchPriority;

	for i = 1, #priorityList do
		local searchType = priorityList[i]:lower();

		if searchType == "barcode" or searchType == "isxn" or searchType == "title" or searchType == "call number" then
			if TrySearch(searchType) then
				break;
			end
		else
			interfaceMngr:ShowMessage("Invalid search type '" .. searchType .. "' specified in SearchPriority in config.", "Configuration Error");
			return false;
		end

		if i == #priorityList then
			GoToAdvanced();
		end
	end
end

function ToggleSearchButtons(isEnabled)
	CatalogForm.SearchButtons.Title.BarButton.Enabled = isEnabled;
	CatalogForm.SearchButtons.ISxN.BarButton.Enabled = isEnabled;
	CatalogForm.SearchButtons.Barcode.BarButton.Enabled = isEnabled;
	CatalogForm.SearchButtons.CallNumber.BarButton.Enabled = isEnabled;
end

function TrySearch(searchType)
	log:Debug("Initiating Barcode search");

	local queryString = nil;
	local encodedSearchTerm = AtlasHelpers.UrlEncode(GetFieldValue("Item", HostAppInfo.SourceFields[searchType]));

	-- Build the query string
	if NotNilOrBlank(encodedSearchTerm) then
		log:Debug("Barcode value found. Adding to querystring.");
		queryString = "&op=AND&" .. HostAppInfo.SearchFields[searchType] .. "=" .. encodedSearchTerm .. "&sort=score+desc%2C+pub_date_isim+desc%2C+title_si+asc&search_field=advanced&commit=Search";
	end

	-- Perform the search
	if queryString then
		Search(queryString);
		return true;
	else
		log:Debug("No " .. searchType .. " value exists to populate the query string. Cancelling the " .. searchType .. " search.");
		return false;
	end
end

function Search(queryString)
	log:Debug("Performing search. Querystring: " .. queryString);
	local completeUrl = Settings.BaseUrl  .. "?utf8=%E2%9C%93"  .. queryString;

	log:Debug("Complete search URL: "  .. completeUrl);

	ToggleSearchButtons(false);
	CatalogForm.Browser:Navigate(completeUrl);
	ToggleSearchButtons(true);
end

function RegisterItemPageHandler()
	CatalogForm.Browser:RegisterPageHandler("custom", "IsItemPage", "ItemPageHandler", true);
end

function IsItemPage()
	log:Debug("Checking if IsItemPage.");
	
	local isItemScript = [[
		(function() { 
			var aCollection = document.getElementsByTagName("a");

			for (let link of aCollection){
				// A "Back to search" link should be indicative of an item page.
				if (link.innerText.toLowerCase() == "back to search"){
					return "True";
				}
			}
			return "False";
		})();
	]];

	local isItem = CatalogForm.Browser:EvaluateScript(isItemScript).Result == "True";

	if isItem then
		log:Debug("Is a record page.");
	else
		log:Debug("Is not a record page.");
	end
	
	if CatalogForm.ItemsGrid.GridControl.Enabled ~= isItem then
		ToggleItemsUIElements(isItem);
	elseif not Settings.AutoRetreiveItems then
		if CatalogForm.RetrieveButton ~= isItem then -- Necessary to nest like this because CatalogForm.RetrieveButton only exists when AutoRetrieveItems is on.
			ToggleItemsUIElements(isItem);
		end
	end
	
	return isItem;
end

function ItemPageHandler()
	log:Debug("ItemPageHandler called.");
	-- Re-registering the handler enables the user to return to the search page and select another record if the selected record isn't a match or no copies are available.
	RegisterItemPageHandler();
end

function RegisterLocateRequestItemHandler()
	CatalogForm.Browser:RegisterPageHandler("custom", "IsLocateRequestItemAttempt", "LocateRequestItemHandler", true);
end

function IsLocateRequestItemAttempt()
	if CatalogForm.Browser.Address:find(":services") then
		return true;
	else
		return false;
	end
end

function LocateRequestItemHandler()
	log:Debug("LocateRequestItemHandler called.");
	
	local url = CatalogForm.Browser.Address;
	CatalogForm.Browser:GoBack();

	local process = Types["System.Diagnostics.Process"]();
	process.StartInfo.FileName = url;
	process.StartInfo.UseShellExecute = true;
	process:Start();

	RegisterLocateRequestItemHandler();
end

function ToggleItemsUIElements(enabled)
	
	if enabled then	
		log:Debug("Enabling UI.");
	else
		log:Debug("Disabling UI.");
	end
	
	if enabled then
		if Settings.AutoRetrieveItems then
			RetrieveItems();
		else
			CatalogForm.RetrieveButton.BarButton.Enabled = true;
		end
	else		
		ClearItems();
		CatalogForm.BibGrid.GridControl.Enabled = false;
		CatalogForm.ItemsGrid.GridControl.Enabled = false;
		if not Settings.AutoRetrieveItems then
			CatalogForm.RetrieveButton.BarButton.Enabled = false;
		end
	end
end

function BuildBibGrid()
	log:Debug("Building bib grid.");

	CatalogForm.BibGrid = CatalogForm.Form:CreateGrid("BibGrid", "Bib Data");

	CatalogForm.BibGrid.TextSize = Types["System.Drawing.Size"].Empty;
	CatalogForm.BibGrid.TextVisible = false;
	CatalogForm.BibGrid.GridControl.Enabled = false;

	local bibGridControl = CatalogForm.BibGrid.GridControl;
	
	bibGridControl:BeginUpdate();

	-- Set the grid view options
	local bibGridView = bibGridControl.MainView;
	bibGridView.OptionsView.ShowIndicator = false;
	bibGridView.OptionsView.ShowGroupPanel = false;
	bibGridView.OptionsView.RowAutoHeight = true;
	bibGridView.OptionsView.ColumnAutoWidth = true;
	bibGridView.OptionsBehavior.AutoExpandAllGroups = true;
	bibGridView.OptionsBehavior.Editable = false;

	-- Add the grid columns
	local bibGridColumn;
	for caption, catalogField in pairs(HostAppInfo.BibGridFields) do
		bibGridColumn = bibGridView.Columns:AddVisible("grid" .. catalogField, caption);
		bibGridColumn.Name = "bibGridColumn" .. caption;
		bibGridColumn.OptionsColumn.ReadOnly = true;
		bibGridColumn.OptionsColumn.AllowFocus = false;
	end

	bibGridControl:EndUpdate();
end

function BuildItemsGrid()
	log:Debug("Building items grid.");
	
	CatalogForm.ItemsGrid = CatalogForm.Form:CreateGrid("ItemsGrid", "Items");
	
	CatalogForm.ItemsGrid.TextSize = Types["System.Drawing.Size"].Empty;
	CatalogForm.ItemsGrid.TextVisible = false;
	CatalogForm.ItemsGrid.GridControl.Enabled = false;
	
	itemsGridControl = CatalogForm.ItemsGrid.GridControl;
	
	itemsGridControl:BeginUpdate();

	-- Set the grid view options
	itemsGridView = itemsGridControl.MainView;
	itemsGridView.OptionsView.ShowIndicator = false;
	itemsGridView.OptionsView.ShowGroupPanel = false;
	itemsGridView.OptionsView.RowAutoHeight = true;
	itemsGridView.OptionsView.ColumnAutoWidth = true;
	itemsGridView.OptionsBehavior.AutoExpandAllGroups = true;
	itemsGridView.OptionsBehavior.Editable = false;
	
	-- Add the grid columns
	local itemsGridColumn;
	for caption, catalogField in pairs(HostAppInfo.ItemGridHoldingFields) do
		itemsGridColumn = itemsGridView.Columns:AddVisible("grid" .. catalogField, caption);
		itemsGridColumn.Name = "itemsGridColumn" .. caption;
		itemsGridColumn.OptionsColumn.ReadOnly = true;
	end

	for caption, catalogField in pairs(HostAppInfo.ItemGridItemFields) do
		itemsGridColumn = itemsGridView.Columns:AddVisible("grid" .. catalogField, caption);
		itemsGridColumn.Name = "itemsGridColumn" .. caption;
		itemsGridColumn.OptionsColumn.ReadOnly = true;
	end

	if NotNilOrBlank(Settings.EResourceLinkField) then
		local gridColumnName = Settings.EResourceLinkField:match(".+=(.+)=");

		if not itemsGridView.Columns:ColumnByName("itemsGridColumn" .. gridColumnName) then
			itemsGridColumn = itemsGridView.Columns:AddVisible("grid" .. gridColumnName, gridColumnName);
			itemsGridColumn.Name = "itemsGridColumn" .. gridColumnName;
			itemsGridColumn.OptionsColumn.ReadOnly = true;
		end
	end

	itemsGridControl:EndUpdate();
	
	itemsGridView:add_FocusedRowChanged(GridFocusedRowChanged);
	itemsGridView:add_DoubleClick(GridRowDoubleClicked);
end

function GridFocusedRowChanged(sender, args)
	if args.FocusedRowHandle > -1 then
		CatalogForm.ImportButton.BarButton.Enabled = true;

		local gridColumnName = Settings.EResourceLinkField:match(".+=(.+)=");

		local itemRow = CatalogForm.ItemsGrid.GridControl.MainView:GetFocusedRow();

		local eResourceUrl = itemRow:get_Item("grid" .. gridColumnName);
		if tostring(eResourceUrl):find("https?://.+") then
			CatalogForm.EResourceLinkButton.BarButton.Enabled = true;
		else
			CatalogForm.EResourceLinkButton.BarButton.Enabled = false;
		end
	else
		CatalogForm.ImportButton.BarButton.Enabled = false;
		CatalogForm.EResourceLinkButton.BarButton.Enabled = false;
	end
end

function GridRowDoubleClicked(sender, args)
	local gridHitInfo = itemsGridView:CalcHitInfo(itemsGridControl:PointToClient(Types["System.Windows.Forms.Cursor"].Position));

	if gridHitInfo.HitTest == Types["DevExpress.XtraGrid.Views.Grid.ViewInfo.GridHitTest"].RowCell then
		DoItemImport();
	end
end

function RetrieveItems()
	log:Debug("Retrieving items");

	local xmlRecordUrl = CatalogForm.Browser.Address .. ".xml";

	-- Cache XML catalog record by URL if it hasn't been already.
	if not xmlRecordsCache[xmlRecordUrl] then
        xmlRecordsCache[xmlRecordUrl] = DownloadString(xmlRecordUrl);
    end

	local xmlRecord = Types["System.Xml.XmlDocument"]();
    xmlRecord:LoadXml(xmlRecordsCache[xmlRecordUrl]);

	CatalogForm.BibGrid.GridControl.MainView:BeginDataUpdate();
	CatalogForm.ItemsGrid.GridControl.MainView:BeginDataUpdate();

	local bibSuccess, bibErr = pcall(function()
		CatalogForm.BibGrid.GridControl.DataSource = BuildBibDataSource(xmlRecord);
	end);
	if not bibSuccess then
		log:Error("Problem encountered while building the bib datasource. Error details:\n" .. TraverseError(bibErr));
		CatalogForm.BibGrid.GridControl.MainView:EndDataUpdate();
		CatalogForm.ItemsGrid.GridControl.MainView:EndDataUpdate();
		return;
	end

	local itemsSuccess, itemsErr = pcall(function()
		CatalogForm.ItemsGrid.GridControl.DataSource = BuildItemsDataSource(xmlRecord);
	end);
	if not itemsSuccess then
		log:Error("Problem encountered while building the items datasource. Error details:\n" .. TraverseError(itemsErr));
		CatalogForm.BibGrid.GridControl.MainView:EndDataUpdate();
		CatalogForm.ItemsGrid.GridControl.MainView:EndDataUpdate();
		return;
	end

	CatalogForm.BibGrid.GridControl.MainView:EndDataUpdate();
	CatalogForm.ItemsGrid.GridControl.MainView:EndDataUpdate();

	CatalogForm.BibGrid.GridControl.Enabled = true;
	CatalogForm.ItemsGrid.GridControl.Enabled = true;
	
	CatalogForm.ItemsGrid.GridControl:Focus();
end

function CreateBibTable()
	local bibTable = Types["System.Data.DataTable"]();

	for caption, catalogField in pairs(HostAppInfo.BibGridFields) do
		bibTable.Columns:Add("grid" .. catalogField);
	end

	for catalogField, aresField in pairs(HostAppInfo.BibImportFields) do
		-- Check if column already exists, since things like ISBN and ISSN may import to the same column.
		if not bibTable.Columns:Contains(aresField) then
			bibTable.Columns:Add(aresField);
		end
	end

	if Settings.ImportEntireWorkPages then
		bibTable.Columns:Add("PagesEntireWork");
	end

	return bibTable;
end

function CreateItemsTable()
	local itemsTable = Types["System.Data.DataTable"]();
	
	for caption, catalogField in pairs(HostAppInfo.ItemGridHoldingFields) do
		itemsTable.Columns:Add("grid" .. catalogField);
	end
	for caption, catalogField in pairs(HostAppInfo.ItemGridItemFields) do
		itemsTable.Columns:Add("grid" .. catalogField);
	end

	for catalogField, aresField in pairs(HostAppInfo.HoldingImportFields) do
		if not itemsTable.Columns:Contains(aresField) then
			itemsTable.Columns:Add(aresField);
		end
	end
	for catalogField, aresField in pairs(HostAppInfo.ItemImportFields) do
		if not itemsTable.Columns:Contains(aresField) then
			itemsTable.Columns:Add(aresField);
		end
	end

	if NotNilOrBlank(Settings.EResourceLinkField) then
		local gridColumnName, aresField = Settings.EResourceLinkField:match(".+=(.+)=(.+)");

		if not itemsTable.Columns:Contains("grid" .. gridColumnName) then
			itemsTable.Columns:Add("grid" .. gridColumnName);
		end

		if not itemsTable.Columns:Contains(aresField) then
			itemsTable.Columns:Add(aresField);
		end
	end
		
	return itemsTable;
end

function ClearItems()
	log:Debug("Clearing Items");
	CatalogForm.BibGrid.GridControl.MainView:BeginDataUpdate();
	CatalogForm.ItemsGrid.GridControl.MainView:BeginDataUpdate();

	CatalogForm.ItemsGrid.GridControl.DataSource = CreateItemsTable();
	CatalogForm.BibGrid.GridControl.DataSource = CreateBibTable();

	CatalogForm.BibGrid.GridControl.MainView:EndDataUpdate();
	CatalogForm.ItemsGrid.GridControl.MainView:EndDataUpdate();
end

function BuildBibDataSource(xmlRecord)
	-- Create row for bib data.
	log:Debug("Building BibDataSource.");

	local bibTable = CreateBibTable();
	local bibRow = bibTable:NewRow();

	for caption, catalogField in pairs(HostAppInfo.BibGridFields) do
		SetColumnValueIfNotNull(bibRow, xmlRecord, nil, catalogField);
	end
	for catalogField, aresField in pairs(HostAppInfo.BibImportFields) do
		SetColumnValueIfNotNull(bibRow, xmlRecord, aresField, catalogField);
	end
	
	if Settings.ImportEntireWorkPages then
		local pages = GetInnerText(xmlRecord, "physical_description"):match("(%d+)%s*[Pp]");

		bibRow:set_Item("PagesEntireWork", pages);
	end

	bibTable.Rows:Add(bibRow);

	return bibTable;
end

function BuildItemsDataSource(xmlRecord)
	log:Debug("Building ItemsDataSource.");

	local holdings = xmlRecord:SelectNodes("//" .. HostAppInfo.CatalogLevels["Holding"]);

	log:Info("Found " .. holdings.Count .. " holdings.");

	local itemsDataTable = CreateItemsTable();
	local bibDataTable = CreateBibTable();

	if NotNilOrBlank(Settings.EResourceIndicator) then
		local eResourceField, eResourceIndicator = Settings.EResourceIndicator:match("(.+)=(.+)");
		local linkXmlField, gridColumnName, linkImportField = Settings.EResourceLinkField:match("(.+)=(.+)=(.+)");

		if GetInnerText(xmlRecord, eResourceField) == eResourceIndicator then
			log:Debug("Electronic resource found. Adding item row for URL.");
			isEResource = true;
			local itemRow = itemsDataTable:NewRow();

			itemRow:set_Item("grid" .. gridColumnName, GetInnerText(xmlRecord, linkXmlField));
			itemRow:set_Item(linkImportField, GetInnerText(xmlRecord, linkXmlField));

			itemsDataTable.Rows:Add(itemRow);
		else
			isEResource = false;
		end
	end
	
	local holdingsEnumerator = holdings:GetEnumerator();

	while holdingsEnumerator:MoveNext() do
		local currentHolding = holdingsEnumerator.Current;

		local items = currentHolding:SelectNodes("//" .. HostAppInfo.CatalogLevels["Item"]);

		log:Info("Found " .. items.Count .. " items.");

		local itemsEnumerator = items:GetEnumerator();
			
		while itemsEnumerator:MoveNext() do
			local currentItem = itemsEnumerator.Current;
			local itemRow = itemsDataTable:NewRow();
			local bibRow = bibDataTable:NewRow();

			-- for catalogField, aresField in pairs(HostAppInfo.BibImportFields) do
			-- 	SetColumnValueIfNotNull(bibRow, xmlRecord, aresField, catalogField);
			-- end

			for caption, catalogField in pairs(HostAppInfo.ItemGridHoldingFields) do
				SetColumnValueIfNotNull(itemRow, currentHolding, nil, catalogField);
			end

			for catalogField, aresField in pairs(HostAppInfo.HoldingImportFields) do
				SetColumnValueIfNotNull(itemRow, currentHolding, aresField, catalogField);
			end

			for caption, catalogField in pairs(HostAppInfo.ItemGridItemFields) do
				if catalogField == "status" then
					for catalogStatus, statusReplacement in pairs(HostAppInfo.DisplayStatuses) do
						if GetInnerText(currentItem, catalogField) == catalogStatus then
							itemRow:set_Item("grid" .. catalogField, statusReplacement);
						else
							SetColumnValueIfNotNull(itemRow, currentItem, nil, catalogField);
						end
					end
				else
					SetColumnValueIfNotNull(itemRow, currentItem, nil, catalogField);
				end
			end

			for catalogField, aresField in pairs(HostAppInfo.ItemImportFields) do
				SetColumnValueIfNotNull(itemRow, currentItem, aresField, catalogField);
			end

			for k = 1, #Settings.CombinedImportFields do
				local firstField, secondField, importField = Settings.CombinedImportFields[k]:match("(.+)=(.+)=(.+)");

				log:Info("Combining " .. firstField .. " and " .. secondField .. " to import into " .. importField .. ".");

				local bibOnlyXml = GetBibOnlyXml(xmlRecord);
				local holdingOnlyXml = GetHoldingOnlyXml(currentHolding);

				local firstFoundField = GetInnerText(bibOnlyXml, firstField) or GetInnerText(holdingOnlyXml, firstField) or GetInnerText(currentItem, firstField);
				local secondFoundField = GetInnerText(bibOnlyXml, secondField) or GetInnerText(holdingOnlyXml, secondField) or GetInnerText(currentItem, secondField);

				local combinedFields;
				if firstFoundField and secondFoundField then
					combinedFields = firstFoundField .. " " .. secondFoundField;

					if itemRow.Table.Columns:Contains(importField) then
						itemRow:set_Item(importField, combinedFields);
					else
						-- Create column if it doesn't already exist.
						itemsDataTable.Columns:Add(importField);
						itemRow:set_Item(importField, combinedFields);
					end
				end
			end

			itemsDataTable.Rows:Add(itemRow);
			bibDataTable.Rows:Add(bibRow);
		end

	end

	return itemsDataTable;
end

function SetColumnValueIfNotNull(dataRow, xmlNode, aresField, catalogField)
	local fieldValue = GetInnerText(xmlNode, catalogField);
	if fieldValue then
		if aresField then
			dataRow:set_Item(aresField, fieldValue);
		else
			dataRow:set_Item("grid" .. catalogField, fieldValue);
		end
	end
end

function GetBibOnlyXml(xmlNode)
	local clonedDocument = xmlNode:Clone();
	local bibOnlyXml = clonedDocument:SelectSingleNode("document");

	bibOnlyXml:RemoveChild(bibOnlyXml:SelectSingleNode(HostAppInfo.CatalogLevels["Holdings"]));

	return bibOnlyXml;
end

function GetHoldingOnlyXml(xmlNode)
	local holdingOnlyXml = xmlNode:Clone();

	holdingOnlyXml:RemoveChild(holdingOnlyXml:SelectSingleNode(HostAppInfo.CatalogLevels["Items"]));

	return holdingOnlyXml;
end

function DoItemImport()
	log:Debug("Performing Import");
	
	local importItemRow = CatalogForm.ItemsGrid.GridControl.MainView:GetFocusedRow();
	local importBibRow = CatalogForm.BibGrid.GridControl.MainView:GetFocusedRow();
	
	if not importItemRow and importBibRow then
		log:Debug("Import rows were nil. Cancelling the import.");
		return;
	end;
	
	-- Update the item object with the new values.
	log:Debug("Updating the item object.");

	local originalIsxn = GetFieldValue("Item", "ISXN");

	for catalogField, aresField in pairs(HostAppInfo.BibImportFields) do
		SetFieldValue("Item", aresField, Cleanup(importBibRow:get_Item(aresField)));
	end

	for catalogField, aresField in pairs(HostAppInfo.HoldingImportFields) do
		SetFieldValue("Item", aresField, Cleanup(importItemRow:get_Item(aresField)));
	end

	for catalogField, aresField in pairs(HostAppInfo.ItemImportFields) do
		SetFieldValue("Item", aresField, Cleanup(importItemRow:get_Item(aresField)));
	end

	for i = 1, #Settings.CombinedImportFields do
		local aresField = Settings.CombinedImportFields[i]:match(".+=.+=(.+)");

		-- E-resources will not have item data beyond the URL, but we still want those fields to be cleared.
		if not isEResource then
			SetFieldValue("Item", aresField, Cleanup(importItemRow:get_Item(aresField)));
		else
			SetFieldValue("Item", aresField, nil);
		end
	end

	if NotNilOrBlank(Settings.EResourceLinkField) then
		local aresField = Settings.EResourceLinkField:match(".+=.+=(.+)");

		if tostring(importItemRow:get_Item(aresField)):find("https?://.+") then
			SetFieldValue("Item", aresField, Cleanup(importItemRow:get_Item(aresField)));
		end
	end

	if Settings.KeepOriginalIsxn and NotNilOrBlank(originalIsxn) and originalIsxn ~= GetFieldValue("Item", "ISXN") then
		SetFieldValue("Item", "ISXN", originalIsxn);
	end

	if Settings.ImportEntireWorkPages then
		SetFieldValue("Item", "PagesEntireWork", importBibRow:get_Item("PagesEntireWork"));
	end
	
	log:Debug("Switching to the detail tab.");
	ExecuteCommand("SwitchTab", {"Details"});
end

function OpenEResourceLink()
	log:Debug("Opening e-resource link in default browser.");

	local gridColumnName = Settings.EResourceLinkField:match(".+=(.+)=");

	local itemRow = CatalogForm.ItemsGrid.GridControl.MainView:GetFocusedRow();
	local url = itemRow:get_Item("grid" .. gridColumnName);

	local process = Types["System.Diagnostics.Process"]();
	process.StartInfo.FileName = url;
	process.StartInfo.UseShellExecute = true;
	process:Start();
end

function GetInnerText(xmlNode, field)
	if xmlNode then
		log:Debug("Getting InnerText of field " .. field .. " in: " .. tostring(xmlNode.OuterXml));
	else
		return nil;
	end

	local xPathSelector;

	-- For nodes derived from xmlRecord, we want to select only the current node.
	if xmlNode.ParentNode then
		xPathSelector = "./";
	else
		xPathSelector = "//";
	end

	log:Debug("xPath expression: " .. tostring(xPathSelector .. field));
	local matchingNode = xmlNode:SelectNodes(xPathSelector .. field);

	if matchingNode.Count > 0 and matchingNode:Item(0).InnerText ~= "" then
		return matchingNode:Item(0).InnerText;
	else
		return nil;
	end
end

function SetNilToEmpty(value)
	if value == nil or value == Types["System.DBNull"].Value then
		value = "";
	end
	return value;
end

function DownloadString(url) -- Downloads document as string from .NET WebClient.
	local webClient = Types["System.Net.WebClient"]();
	function DLString(url)
		webClient.Headers:Clear();
		webClient.Headers:Set("Accept", "application/xml");
		webClient.Encoding = Types["System.Text.Encoding"].UTF8;
		local results = webClient:DownloadString(url);

		return results;
	end
	
	local success, results = pcall(DLString, url);
	if not success then
		log:Debug("Problem with URL in WebClient: " .. url .. "\nError: " .. tostring(results));
	end
	
	webClient:Dispose();

	return results;
end

function NotNilOrBlank(str)
	if str and str ~= "" and str ~= Types["System.DBNull"].Value then
		return true;
	else
		return false;
	end
end

function SetNilToEmpty(value)
	if ((value == nil) or (value == Types["System.DBNull"].Value)) then
		value = "";
	end
	return value;
end

-- Performs character decoding and trimming on strings to be imported.
function Cleanup(value)
	if not NotNilOrBlank(value) then
		log:Debug("Value was nil or empty. Skipping string cleanup.");
        return value;
	end

	value = value:gsub("^%s*", ""):gsub("%s*$", "");

	if Settings.RemoveTrailingSpecialCharacters then
		value = value:gsub("%s*$", ""):gsub("[\\/%+,;:%-=%.]$", "");
	end

	log:Debug("Decoding HTML-encoded chracters for " .. value);
	value = Types["System.Net.WebUtility"].HtmlDecode(value);

	return value;
end

function TraverseError(e)
    if not e.GetType then
        -- Not a .NET type
        return e;
    else
        if not e.Message then
            -- Not a .NET exception
            return e;
        end
    end

    log:Debug(e.Message);

    if e.InnerException then
        return TraverseError(e.InnerException);
    else
        return e.Message;
    end
end