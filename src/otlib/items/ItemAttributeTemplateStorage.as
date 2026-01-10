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
     * Manages attribute templates stored in config/templates/*.xml
     * Each template is a separate XML file containing basic info and attributes.
     */
    public class ItemAttributeTemplateStorage
    {
        // --------------------------------------------------------------------------
        // PROPERTIES
        // --------------------------------------------------------------------------

        private var _templatesDir:String;
        private var _templateNames:Vector.<String>;

        // --------------------------------------------------------------------------
        // CONSTRUCTOR
        // --------------------------------------------------------------------------

        public function ItemAttributeTemplateStorage()
        {
            _templateNames = new Vector.<String>();
        }

        // --------------------------------------------------------------------------
        // PUBLIC METHODS
        // --------------------------------------------------------------------------

        /**
         * Initializes storage with config path. Templates stored in configPath/templates/
         */
        public function initialize(configPath:String):Boolean
        {
            _templatesDir = configPath + "/templates";

            var dir:File = new File(_templatesDir);
            if (!dir.exists)
            {
                try
                {
                    dir.createDirectory();
                }
                catch (e:Error)
                {
                    return false;
                }
            }

            return loadTemplateNames();
        }

        public function getTemplateNames():Vector.<String>
        {
            return _templateNames.slice();
        }

        public function hasTemplate(name:String):Boolean
        {
            return _templateNames.indexOf(name) >= 0;
        }

        /**
         * Creates and saves a template.
         * @param name Template name (used as filename)
         * @param basicInfo Object with: name, plural, article, weight, description
         * @param attributes Dictionary of attribute key/value pairs
         */
        public function createTemplate(name:String, basicInfo:Object, attributes:Dictionary):Boolean
        {
            if (!name || name.length == 0)
                return false;

            var xml:String = '<?xml version="1.0" encoding="UTF-8"?>\n';
            xml += '<template name="' + escapeXml(name) + '">\n';

            // Basic info
            xml += '\t<basic>\n';
            if (basicInfo)
            {
                xml += '\t\t<name>' + escapeXml(basicInfo.name || "") + '</name>\n';
                xml += '\t\t<plural>' + escapeXml(basicInfo.plural || "") + '</plural>\n';
                xml += '\t\t<article>' + escapeXml(basicInfo.article || "") + '</article>\n';
                xml += '\t\t<weight>' + escapeXml(basicInfo.weight || "") + '</weight>\n';
                xml += '\t\t<description>' + escapeXml(basicInfo.description || "") + '</description>\n';
            }
            xml += '\t</basic>\n';

            // Attributes (supports nested)
            xml += '\t<attributes>\n';
            if (attributes)
            {
                xml += serializeAttributes(attributes, 2);
            }
            xml += '\t</attributes>\n';
            xml += '</template>\n';

            try
            {
                var file:File = new File(_templatesDir + "/" + sanitizeName(name) + ".xml");
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.WRITE);
                stream.writeUTFBytes(xml);
                stream.close();

                if (_templateNames.indexOf(name) < 0)
                {
                    _templateNames.push(name);
                    _templateNames.sort(Array.CASEINSENSITIVE);
                }
                return true;
            }
            catch (e:Error)
            {
                trace("createTemplate error:", e.message);
            }
            return false;
        }

        /**
         * Loads a template and returns an object with basicInfo and attributes.
         */
        public function loadTemplate(name:String):Object
        {
            var file:File = new File(_templatesDir + "/" + sanitizeName(name) + ".xml");
            if (!file.exists)
                return null;

            try
            {
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.READ);
                var content:String = stream.readUTFBytes(stream.bytesAvailable);
                stream.close();

                var xml:XML = new XML(content);
                var result:Object = {
                        name: xml.@name.toString() || name,
                        basicInfo: {},
                        attributes: new Dictionary()
                    };

                // Parse basic info
                if (xml.basic.length() > 0)
                {
                    result.basicInfo.name = xml.basic.name.toString();
                    result.basicInfo.plural = xml.basic.plural.toString();
                    result.basicInfo.article = xml.basic.article.toString();
                    result.basicInfo.weight = xml.basic.weight.toString();
                    result.basicInfo.description = xml.basic.description.toString();
                }

                // Parse attributes (supports nested)
                result.attributes = parseAttributes(xml.attributes);

                return result;
            }
            catch (e:Error)
            {
                trace("loadTemplate error:", e.message);
            }
            return null;
        }

        public function removeTemplate(name:String):Boolean
        {
            var file:File = new File(_templatesDir + "/" + sanitizeName(name) + ".xml");
            try
            {
                if (file.exists)
                    file.deleteFile();

                var idx:int = _templateNames.indexOf(name);
                if (idx >= 0)
                    _templateNames.splice(idx, 1);
                return true;
            }
            catch (e:Error)
            {
                trace("removeTemplate error:", e.message);
            }
            return false;
        }

        public function get templateCount():int
        {
            return _templateNames.length;
        }

        // --------------------------------------------------------------------------
        // PRIVATE METHODS
        // --------------------------------------------------------------------------

        private function loadTemplateNames():Boolean
        {
            _templateNames = new Vector.<String>();
            var dir:File = new File(_templatesDir);
            if (!dir.exists || !dir.isDirectory)
                return true;

            try
            {
                var files:Array = dir.getDirectoryListing();
                for each (var file:File in files)
                {
                    if (file.extension && file.extension.toLowerCase() == "xml")
                    {
                        var name:String = file.name.replace(".xml", "");
                        _templateNames.push(name);
                    }
                }
                _templateNames.sort(Array.CASEINSENSITIVE);
                return true;
            }
            catch (e:Error)
            {
                trace("loadTemplateNames error:", e.message);
            }
            return false;
        }

        private function sanitizeName(name:String):String
        {
            // Replace invalid filename characters with underscore
            var result:String = name;
            var invalid:Array = ["\\", "/", ":", "*", "?", '"', "<", ">", "|"];
            for each (var ch:String in invalid)
            {
                result = result.split(ch).join("_");
            }
            return result;
        }

        /**
         * Recursively serializes attributes to XML string.
         * Nested attributes are stored as child elements.
         */
        private function serializeAttributes(attrs:Dictionary, indent:int):String
        {
            var result:String = "";
            var tabs:String = "";
            for (var i:int = 0; i < indent; i++)
                tabs += "\t";

            for (var key:String in attrs)
            {
                var value:* = attrs[key];

                // Check if value is an object with nested 'children' property
                if (value is Object && value.hasOwnProperty("children") && value.children is Dictionary)
                {
                    // Nested attribute with children
                    var attrValue:String = value.hasOwnProperty("value") ? String(value.value) : "";
                    result += tabs + '<attribute key="' + escapeXml(key) + '" value="' + escapeXml(attrValue) + '">\n';
                    result += serializeAttributes(value.children, indent + 1);
                    result += tabs + '</attribute>\n';
                }
                else
                {
                    // Simple attribute
                    result += tabs + '<attribute key="' + escapeXml(key) + '" value="' + escapeXml(String(value)) + '"/>\n';
                }
            }
            return result;
        }

        /**
         * Recursively parses attributes from XMLList or XML node.
         * Works for both root level (XMLList) and nested level (XML).
         */
        private function parseAttributes(parentNode:*):Dictionary
        {
            var result:Dictionary = new Dictionary();
            var attrList:XMLList;

            // Handle both XMLList (root) and XML (nested)
            // Access child elements named "attribute"
            if (parentNode is XMLList)
                attrList = parentNode.attribute;
            else if (parentNode is XML)
                attrList = parentNode.attribute;
            else
                return result;

            for each (var attr:XML in attrList)
            {
                var key:String = attr.@key.toString();
                var value:String = attr.@value.toString();

                // Check for nested children
                if (attr.attribute.length() > 0)
                {
                    result[key] = {
                            value: value,
                            children: parseAttributes(attr)
                        };
                }
                else
                {
                    result[key] = value;
                }
            }

            return result;
        }

        private function escapeXml(str:String):String
        {
            if (!str)
                return "";
            var result:String = str;
            result = result.split("&").join("&amp;");
            result = result.split("<").join("&lt;");
            result = result.split(">").join("&gt;");
            result = result.split('"').join("&quot;");
            result = result.split("'").join("&apos;");
            return result;
        }
    }
}
