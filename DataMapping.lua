HostAppInfo = {}
HostAppInfo.Icons = {};
HostAppInfo.SourceFields = {};
HostAppInfo.SearchFields = {};
HostAppInfo.PageHandlerText = {};
HostAppInfo.BibGridFields = {};
HostAppInfo.ItemGridHoldingFields = {};
HostAppInfo.ItemGridItemFields = {};
HostAppInfo.CatalogLevels = {};
HostAppInfo.BibImportFields = {};
HostAppInfo.HoldingImportFields = {};
HostAppInfo.ItemImportFields = {};
HostAppInfo.DisplayStatuses = {};

-- DataMapping Configuration for the Ares Blacklight Catalog addon
-- The text within the brackets is referred to as the "key," and the text to the right of the 
-- equal sign is the "value." Example: HostAppInfo.Example["key"] = "value";

-- Icons for addon ribbon buttons. The key is the button name and should not be changed. The 
-- value is the name of the icon file to use for the button.
HostAppInfo.Icons["ISxNSearch"] = "Find32";
HostAppInfo.Icons["CallNumberSearch"] = "Search32";
HostAppInfo.Icons["TitleSearch"] = "SortByName32";
HostAppInfo.Icons["BarcodeSearch"] = "Search32";
HostAppInfo.Icons["RetrieveItems"] = "Record32";
HostAppInfo.Icons["Import"] = "Import32";
HostAppInfo.Icons["AdvancedSearch"] = "Options32";
HostAppInfo.Icons["EResourceLink"] = "OpenBrowser32";

-- Source fields for each search type. The key is the search type and should not be changed. 
-- The value is the Ares Item field to be used for the search type.
HostAppInfo.SourceFields["isxn"] = "ISXN";
HostAppInfo.SourceFields["title"] = "Title";
HostAppInfo.SourceFields["author"] = "Author";
HostAppInfo.SourceFields["barcode"] = "ItemBarcode";

-- Name of search fields in the query URL. The key is the search type and should not be 
-- changed. The value is the name of the query field used in the URL built by Blacklight when 
-- performing a search, some of which are only available using the advanced search function. 
-- For example, this is part of a URL generated when performing an advanced search for a publisher 
-- with the name "DOCUMENTATION EXAMPLE":
-- https://search.xxxxx.xxxxx.edu/catalog?utf8=%E2%9C%93&op=AND&all_fields_advanced=&title_advanced=&title_wildcard_advanced=&author_advanced=&subject_advanced=&title_series_advanced=&publisher_advanced=DOCUMENTATION+EXAMPLE&identifier_advanced=&call_number_advanced=
-- In this example the field for publisher is "publisher_advanced."
HostAppInfo.SearchFields["title"] = "title_advanced";
HostAppInfo.SearchFields["isxn"] = "identifier_advanced";
HostAppInfo.SearchFields["barcode"] = "";
HostAppInfo.SearchFields["callnumber"] = "call_number_advanced";

-- Catalog levels
-- The key is the level, which should not be changed. The value is the XML field value 
-- denoting that level in the catalog XML. For example:

--[[
<issn/>
<supplemental_links> </supplemental_links>
<physical_holdings>
    <physical_holding>
        <call_number>PN6725 .H6 2001</call_number>
        <items>
            <item>
                <library>SMEMORIAL</library>
                <location>GENERAL STACKS</location>
                <barcode>800632985</barcode>
                <volume_or_issue>V.1</volume_or_issue>
                <status>On shelf</status>
            </item>
            <item>
                <library>SMEMORIAL</library>
                <location>B COMPACT</location>
                <barcode>800658165</barcode>
                <volume_or_issue>V.2</volume_or_issue>
                <status>On shelf</status>
            </item>
--]]
-- In this example of a partial XML record, the field names we're looking for are 
-- "physical_holding" for the holding level and "item" for the item level.
HostAppInfo.CatalogLevels["Holding"] = "physical_holding";
HostAppInfo.CatalogLevels["Item"] = "item";

-- Bib-level fields to display in the bib grid. The key is the column display name, and the 
-- values are the corresponding catalog XML field. These values must be at the bib level in 
-- the catalog XML record. Fields can be added to this section or removed as desired.
HostAppInfo.BibGridFields["Title"] = "title";
HostAppInfo.BibGridFields["Edition"] = "edition";

-- Holding-level fields to display in the item grid. The key is the column display name, and 
-- the values are the corresponding catalog XML field. These values must be at the holding 
-- level in the catalog XML record. Fields can be added to this section or removed as desired.
HostAppInfo.ItemGridHoldingFields["Call #"] = "call_number";

-- Item-level fields to display in the item grid. The key is the column display name, and the 
-- values are the corresponding catalog XML field. These values must be at the item level in 
-- the catalog XML record. Fields can be added to this section or removed as desired.
HostAppInfo.ItemGridItemFields["Location"] = "location";
HostAppInfo.ItemGridItemFields["Barcode"] = "barcode";
HostAppInfo.ItemGridItemFields["Status"] = "status";
HostAppInfo.ItemGridItemFields["Volume/Issue"] = "volume_or_issue";

-- Bib-level fields to import. The key is the name of the catalog XML field, and the value is 
-- the name of the Ares Item field to import to. Must be at the bib level in the XML catalog 
-- record. Fields can be added to this section or removed as desired.
HostAppInfo.BibImportFields["title"] = "Title";
HostAppInfo.BibImportFields["author"] = "Author";
HostAppInfo.BibImportFields["edition"] = "Edition";
HostAppInfo.BibImportFields["editor"] = "Editor";
HostAppInfo.BibImportFields["publisher"] = "Publisher";
HostAppInfo.BibImportFields["publication_date"] = "PubDate";
HostAppInfo.BibImportFields["issn"] = "ISXN";

-- Holding-level fields to import. The key is the name of the catalog XML field, and the 
-- value is the name of the Ares Item field to import to. Must be at the holding level in the 
-- catalog XML record. Fields can be added to this section or removed as desired.
HostAppInfo.HoldingImportFields["call_number"] = "CallNumber";

-- Item-level fields to import. The key is the name of the catalog XML field, and the value is
-- the name of the Ares Item field to import to. Must be at the item level in the catalog XML
-- record. Fields can be added to this section or removed as desired.
HostAppInfo.ItemImportFields["barcode"] = "ItemBarcode";

-- Alternate statuses to display in the grid. For example, if you want to display a status of
-- "Item on Shelf" as "Available" and other statuses as "Not Available." The key is the status
-- displayed in the catalog XML record and the value is the status you want displayed in the
-- grid instead. The XML field must be named "status" for this to work. Fields can be added
-- to this section or removed as desired.
HostAppInfo.DisplayStatuses["Item in place"] = "Available";

return HostAppInfo;