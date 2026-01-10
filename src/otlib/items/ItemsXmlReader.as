/*
*  Copyright (c) 2014-2023 Object Builder <https://github.com/ottools/ObjectBuilder>
*
*  Permission is hereby granted, free of charge, to any person obtaining a copy
*  of this software and associated documentation files (the "Software"), to deal
*  in the Software without restriction, including without limitation the rights
*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*  copies of the Software, and to permit persons to whom the Software is
*  furnished to do so, subject to the following conditions:
*
*  The above copyright notice and this permission notice shall be included in
*  all copies or substantial portions of the Software.
*
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
*  THE SOFTWARE.
*/

package otlib.items
{
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.Dictionary;

    /**
     * Reads items.xml file and populates ServerItem names and attributes.
     * Detects unknown attributes not defined in itemAttributes.xml.
     */
    public class ItemsXmlReader
    {
        // --------------------------------------------------------------------------
        // PROPERTIES
        // --------------------------------------------------------------------------

        private var _directory:String;
        private var _file:String;
        private var _knownAttributes:Dictionary;
        private var _missingAttributes:Dictionary;
        private var _knownTagAttributes:Dictionary;
        private var _missingTagAttributes:Dictionary;

        // --------------------------------------------------------------------------
        // CONSTRUCTOR
        // --------------------------------------------------------------------------

        public function ItemsXmlReader()
        {
            _knownAttributes = new Dictionary();
            _missingAttributes = new Dictionary();
            _knownTagAttributes = new Dictionary();
            _missingTagAttributes = new Dictionary();

            // Default known tag attributes
            _knownTagAttributes["name"] = true;
            _knownTagAttributes["article"] = true;
            _knownTagAttributes["plural"] = true;
            _knownTagAttributes["editorsuffix"] = true;
        }

        // --------------------------------------------------------------------------
        // PUBLIC METHODS
        // --------------------------------------------------------------------------

        public function get directory():String
        {
            return _directory;
        }
        public function get file():String
        {
            return _file;
        }

        /**
         * Gets list of nested attributes found in items.xml but not in itemAttributes.xml
         */
        public function getMissingAttributes():Array
        {
            var result:Array = [];
            for (var key:String in _missingAttributes)
            {
                result.push(key);
            }
            result.sort();
            return result;
        }

        /**
         * Gets list of tag attributes found in items.xml but not in config
         */
        public function getMissingTagAttributes():Array
        {
            var result:Array = [];
            for (var key:String in _missingTagAttributes)
            {
                result.push(key);
            }
            result.sort();
            return result;
        }

        /**
         * Sets known tag attributes from config (placement="tag")
         */
        public function setKnownTagAttributes(keys:Array):void
        {
            _knownTagAttributes = new Dictionary();
            for each (var key:String in keys)
            {
                _knownTagAttributes[key] = true;
            }
        }

        /**
         * Sets the list of known attributes (keys) for validation.
         * @param keys Array of attribute key strings.
         */
        public function setKnownAttributes(keys:Array):void
        {
            _knownAttributes = new Dictionary();
            if (!keys)
                return;

            for each (var key:String in keys)
            {
                if (key)
                {
                    _knownAttributes[key.toLowerCase()] = true;
                }
            }
        }

        /**
         * Loads known attributes from itemAttributes.xml (legacy)
         */
        public function loadKnownAttributes(attributesXmlPath:String):Boolean
        {
            try
            {
                var file:File = new File(attributesXmlPath);
                if (!file.exists)
                    return false;

                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.READ);
                var content:String = stream.readUTFBytes(stream.bytesAvailable);
                stream.close();

                var xml:XML = new XML(content);

                for each (var attrElement:XML in xml.attribute)
                {
                    var key:String = String(attrElement.@key);
                    if (key && key.length > 0)
                    {
                        _knownAttributes[key.toLowerCase()] = {
                                type: String(attrElement.@type),
                                category: String(attrElement.@category),
                                description: String(attrElement.@description)
                            };
                    }
                }

                return true;
            }
            catch (error:Error)
            {
                trace("loadKnownAttributes error:", error.message);
                return false;
            }

            return false;
        }

        /**
         * Reads items.xml (or specified file) and populates ServerItemList with names and attributes
         *
         * @param path Path to the XML file
         * @param items ServerItemList to populate
         * @return true on success, false on failure
         */
        public function read(path:String, items:ServerItemList):Boolean
        {
            if (!path)
                return false;

            var xmlFile:File = new File(path);
            if (!xmlFile.exists || xmlFile.isDirectory)
                return false;

            if (!items)
                return false;

            // Clear missing attributes from previous read
            _missingAttributes = new Dictionary();

            try
            {
                var stream:FileStream = new FileStream();
                stream.open(xmlFile, FileMode.READ);
                var content:String = stream.readUTFBytes(stream.bytesAvailable);
                stream.close();

                var xml:XML = new XML(content);

                for each (var itemElement:XML in xml.item)
                {
                    // Handle single item with id attribute
                    if (itemElement.@id.length() > 0)
                    {
                        var id:uint = uint(itemElement.@id);
                        var item:ServerItem = items.getByServerId(id);
                        if (item)
                        {
                            parseItem(item, itemElement);
                        }
                    }
                    // Handle range with fromid/toid
                    else if (itemElement.@fromid.length() > 0 && itemElement.@toid.length() > 0)
                    {
                        var fromId:uint = uint(itemElement.@fromid);
                        var toId:uint = uint(itemElement.@toid);

                        for (var rangeId:uint = fromId; rangeId <= toId; rangeId++)
                        {
                            var rangeItem:ServerItem = items.getByServerId(rangeId);
                            if (rangeItem)
                            {
                                parseItem(rangeItem, itemElement);
                            }
                        }
                    }
                }

                _file = xmlFile.nativePath;
                _directory = xmlFile.parent ? xmlFile.parent.nativePath : "";

                return true;
            }
            catch (error:Error)
            {
                trace("ItemsXmlReader error:", error.message);
                return false;
            }

            return false;
        }

        /**
         * Writes missing attributes to a file
         */
        public function writeMissingAttributes(filePath:String):Boolean
        {
            var missing:Array = getMissingAttributes();
            if (missing.length == 0)
                return true; // Nothing to write

            try
            {
                var xml:String = '<?xml version="1.0" encoding="UTF-8"?>\n';
                xml += '<!-- Attributes found in items.xml but not defined in itemAttributes.xml -->\n';
                xml += '<missing_attributes>\n';

                for each (var key:String in missing)
                {
                    xml += '\t<attribute key="' + key + '" type="string" category="unknown" description="" />\n';
                }

                xml += '</missing_attributes>\n';

                var file:File = new File(filePath);
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.WRITE);
                stream.writeUTFBytes(xml);
                stream.close();

                return true;
            }
            catch (error:Error)
            {
                trace("writeMissingAttributes error:", error.message);
                return false;
            }

            return false;
        }

        // --------------------------------------------------------------------------
        // PROTECTED METHODS
        // --------------------------------------------------------------------------

        /**
         * Parses a single item element and sets the ServerItem properties.
         * Reads ALL attributes from the <item> tag dynamically.
         * Tracks unknown tag attributes not in config.
         */
        protected function parseItem(item:ServerItem, element:XML):void
        {
            // Reserved attributes that are not stored
            var reserved:Object = {"id": true, "fromid": true, "toid": true};

            // Read ALL attributes from the <item> tag dynamically
            for each (var attr:XML in element.attributes())
            {
                var attrName:String = attr.name().toString();
                var attrValue:String = String(attr);

                // Skip reserved attributes
                if (reserved[attrName])
                    continue;

                // Track unknown tag attributes
                if (!_knownTagAttributes[attrName])
                {
                    _missingTagAttributes[attrName] = true;
                }

                // Handle known properties with dedicated setters
                switch (attrName)
                {
                    case "name":
                        item.nameXml = attrValue;
                        break;
                    case "article":
                        item.article = attrValue;
                        break;
                    case "plural":
                        item.plural = attrValue;
                        break;
                    default:
                        // Store other tag attributes (like editorsuffix) in xmlAttributes
                        item.setXmlAttribute(attrName, attrValue);
                        break;
                }
            }

            // Parse nested attribute elements
            parseAttributes(element, item);
        }

        /**
         * Recursively parses attributes from an XML element.
         * Detects nested attributes (data/table) and stores them as Dictionary.
         */
        protected function parseAttributes(element:XML, item:ServerItem):void
        {
            for each (var attrElement:XML in element.attribute)
            {
                var key:String = String(attrElement.@key);
                var value:Object = null;

                // Check for nested attributes
                if (attrElement.attribute.length() > 0)
                {
                    var nestedAttributes:Dictionary = new Dictionary();

                    // Check if the parent attribute itself has a value (Canary style)
                    var parentValue:String = String(attrElement.@value);
                    if (parentValue && parentValue.length > 0)
                    {
                        nestedAttributes["_parentValue"] = parentValue;
                    }

                    for each (var childAttr:XML in attrElement.attribute)
                    {
                        var childKey:String = String(childAttr.@key);
                        var childValue:String = String(childAttr.@value);
                        if (childKey)
                        {
                            nestedAttributes[childKey] = childValue;
                        }
                    }
                    value = nestedAttributes;
                }
                else
                {
                    value = String(attrElement.@value);
                }

                if (key && value !== null)
                {
                    item.setXmlAttribute(key, value);

                    // Check if this is a known attribute (case-insensitive)
                    var keyLower:String = key.toLowerCase();
                    if (!_knownAttributes[keyLower])
                    {
                        _missingAttributes[key] = true;
                    }
                }
            }
        }
    }
}
