# Extracting TFS Attributes using AI

This directory contains XML files that define the valid attributes for different versions of The Forgotten Server (TFS). These files are used by ObjectBuilder to know which properties can be assigned to items.

To generate or update these files for a new server version, you can use an AI (like ChatGPT, Claude, or Gemini) to analyze the source code.

## Prerequisites

You need the C++ source code of the server you want to analyze. Specifically:
1.  **`src/items.cpp`**: Contains the main parsing logic in `Items::parseItemNode`.
2.  **`src/tools.cpp`** (or `const.h` / `enums.h` in older versions): Contains the lists of effects, shoot types, and ammo types.

## The Prompt

Copy and paste the following prompt into the AI, along with the content of the files mentioned above.

***

**System / Context:**
You are an expert C++ developer and OpenTibia server specialist. Your task is to analyze C++ source code and generate an XML schema definition for item attributes.

**Task:**
1.  Analyze the provided `items.cpp` file, specifically the `Items::parseItemNode` function (or equivalent). Identify all string keys used to parse item attributes (e.g., `if (tmpStrValue == "armor")`).
2.  Identify the expected data type for each attribute (number, boolean, or string).
3.  For attributes that map to enums (like `shootType`, `effect`, `ammoType`, `fluidSource`, `floorChange`, `corpseType`), looking at the helper functions (e.g., `getShootType`, `getMagicEffect`) or the provided `tools.cpp`/header files to extract the **full list of valid string values**.
4.  Generate an XML file following the structure below.

**Required XML Structure:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<attributes server="tfs_version_here" displayName="TFS Version Name" supportsFromToId="true">
    <category name="Category Name">
        <!-- usage: -->
        <attribute key="attribute_name_in_source" type="number|string|boolean|mixed"/>
        <!-- if the attribute has specific allowed string values (enums): -->
        <attribute key="attribute_name" type="string" values="val1,val2,val3"/>

        <!-- For nested attributes (data/table): -->
        <!-- Note: This requires the attribute parser to support recursive "attribute" nodes. -->
        <attribute key="parent_attribute_key" type="data" value="optional_default_value">
             <attribute key="child_attribute_key" type="number"/>
             <attribute key="child_attribute_string" type="string"/>
        </attribute>
    </category>
</attributes>
```

**Attribute Types:**
*   `string`: Text value.
*   `number`: Numeric value (integer or float).
*   `boolean`: `true` or `false`.
*   `mixed`: Can be one of the predefined `values` OR any custom string/number (combo box with text input).
*   `data`: (or `table`) Represents a parent attribute that contains nested child attributes.

**Categorization Rules:**
*   **General**: `name`, `description`, `weight`, `article`, etc.
*   **Combat**: `attack`, `defense`, `armor`, `range`, `hitchance`, etc.
*   **Equipment**: `slotType`, `weaponType`, `ammoType`, `shootType`, `effect`.
*   **Properties**: `moveable`, `blocking`, `pickupable`, `floorChange`, `corpseType`.
*   **Container**: `containerSize`, `fluidSource`.
*   **Duration/Transform**: `duration`, `decayTo`, `transformTo`, etc.
*   **Skills/Absorb/Elements**: Group skill boosts, damage absorption, and elemental damage into their own categories.

**Input Files:**
I will paste the content of `items.cpp` and `tools.cpp` below. Please ignore any attributes that are NOT present in the parsing logic.

***
