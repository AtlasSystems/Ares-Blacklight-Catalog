# Ares Blacklight Catalog Search Addon

## Summary

This addon searches the Blacklight catalog and imports values from catalog records into Ares. Retrieved catalog records are displayed in two grids along with the browser; one grid with the bib-level data on the left and the other with item-level records for importing on right. Records can be imported into Ares by highlighting a row in the item grid and clicking the Import button. The selected record can also be imported by pressing Ctrl+I. 

# Data Mapping
The icons for the buttons used by the addon, Blacklight search fields used for each search type, fields to display in the grids, fields to be imported into Ares, and alternate statuses to be displayed in the grid are all configurable in the addon's DataMapping.lua file. Instructions for configuring each section are written as comments in the file.

# Prerequisites
To use this addon, your Blacklight catalog records must have XML documents accessible by appending ".xml" to the URL of the catalog record. These records must have clearly delineated bib-, holding-, and item-level elements. For more information about configuring XML records in Blacklight, please refer to Emory Unviersity's documentation: https://github.com/emory-libraries/blacklight-catalog/blob/main/app/views/catalog/SHOW_XML_README.md

## Settings

**BaseUrl (string)**

The base URL for the Blacklight catalog. This is the portion of the URL to the left of the ? when you perform a search. Default: blank

**AdvancedSearchUrl (string)**

The URL for the Blacklight catalog's advanced search page. Default: blank

**AutoSearch (Boolean)**

Defines whether the search should be automatically performed when the form opens. Default: True

**SearchPriority (string)**

The type of search to automatically run in order of search priority and separated by a comma. The valid search types are barcode, isxn, call number, and title. Default: barcode,call number,isxn,title

**AutoRetrieveItems (Boolean)**

Defines whether the addon should automaticaly retrieve items related to a record being viewed. Default: True

**KeepOriginalIsxn (Boolean)**

Defines whether or not to overwrite the ISXN field when importing. Default: True

**EResourceIndicator (string)**

The bib-level catalog XML field and value that indicates a record can be accessed electronically. A row in the grid will be created with a link to the resource if possible. Leave blank if you do not wish to use this feature. Format is the XML field name and that field's value when a record is an electronic resource, separated by an =. Default: is_electronic_holding=true

**EResourceLinkField (string)**

The bib-level catalog XML field that contains the link for an electronic resource and the Ares field it should be imported to. Format is the XML field name and the Ares field separated by an =. Default: link=Location

**CombinedImportFields (string)**

A list of item-level XML fields that should be combined when importing and their corresponding Ares fields. Format is [first XML field]=[second XML field]=[Ares field] with each set separated by a comma. Fields will be concatenated with a space between them. Do not define these fields in the ItemImportFields table in DataMapping.lua. Default: library=location=ShelfLocation

**DisplayInvalidSearchMessage (Boolean)**

Defines whether or not the addon should display a message when an invalid search is performed by clicking a ribbon button. Default: False

**RemoveTrailingSpecialCharacters (Boolean)**

Defines whether to remove trailing special characters on import or not. The included special characters are: \ / + , ; : - = . Default: True