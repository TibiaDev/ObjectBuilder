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
     * Manages loading and caching of attribute definitions per server type.
     * Reads from XML files in config/attributes/ folder.
     */
    public class ItemAttributeStorage
    {
        // --------------------------------------------------------------------------
        // SINGLETON
        // --------------------------------------------------------------------------

        private static var s_instance:ItemAttributeStorage;

        public static function getInstance():ItemAttributeStorage
        {
            if (!s_instance)
                s_instance = new ItemAttributeStorage();
            return s_instance;
        }

        // --------------------------------------------------------------------------
        // PROPERTIES
        // --------------------------------------------------------------------------

        /** Cached attributes by server name */
        private var _serverCache:Dictionary;

        /** Cached server metadata (displayName, supportsFromToId) */
        private var _serverMetadata:Dictionary;

        /** Path to attributes folder */
        private var _attributesPath:String;

        /** Currently loaded server name */
        private var _currentServer:String;

        /** List of available servers */
        private var _availableServers:Array;

        // --------------------------------------------------------------------------
        // GETTERS
        // --------------------------------------------------------------------------

        public function get isInitialized():Boolean
        {
            return _attributesPath != null;
        }

        // --------------------------------------------------------------------------
        // CONSTRUCTOR
        // --------------------------------------------------------------------------

        public function ItemAttributeStorage()
        {
            _serverCache = new Dictionary();
            _serverMetadata = new Dictionary();
            _availableServers = [];
        }

        // --------------------------------------------------------------------------
        // PUBLIC METHODS
        // --------------------------------------------------------------------------

        /**
         * Initializes the registry by scanning the attributes folder
         */
        public function initialize(attributesPath:String):Boolean
        {
            _attributesPath = attributesPath;

            var dir:File = new File(attributesPath);
            if (!dir.exists || !dir.isDirectory)
                return false;

            // Scan for XML files
            _availableServers = [];
            var files:Array = dir.getDirectoryListing();

            for each (var file:File in files)
            {
                if (file.extension == "xml")
                {
                    var serverName:String = file.name.replace(".xml", "");
                    _availableServers.push(serverName);
                }
            }

            _availableServers.sort();
            return _availableServers.length > 0;
        }

        /**
         * Gets list of available server names
         */

        /**
         * Gets list of available servers with display names.
         * Returns array of objects: {server: "tfs1.6", displayName: "TFS 1.6"}
         */
        public function getAvailableServers():Array
        {
            var result:Array = [];
            for each (var serverName:String in _availableServers)
            {
                // Ensure server is loaded to get metadata
                if (!_serverMetadata[serverName])
                    loadServer(serverName);

                result.push({
                            server: serverName,
                            displayName: getDisplayName(serverName)
                        });
            }
            return result;
        }

        /**
         * Loads attributes for a specific server
         * @param serverName The server name (e.g., "tfs1.6")
         * @param forceReload If true, bypasses cache and reloads from file
         */
        public function loadServer(serverName:String, forceReload:Boolean = false):Vector.<ItemAttribute>
        {
            // Check cache first (unless force reload)
            if (!forceReload && _serverCache[serverName])
                return _serverCache[serverName] as Vector.<ItemAttribute>;

            var filePath:String = _attributesPath + "/" + serverName + ".xml";
            var file:File = new File(filePath);

            if (!file.exists)
                return null;

            try
            {
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.READ);
                var content:String = stream.readUTFBytes(stream.bytesAvailable);
                stream.close();

                var xml:XML = new XML(content);
                var attributes:Vector.<ItemAttribute> = new Vector.<ItemAttribute>();

                // Parse metadata
                var metadata:Object = {
                        displayName: xml.@displayName.toString() || serverName,
                        supportsFromToId: xml.@supportsFromToId.toString() == "true"
                    };
                _serverMetadata[serverName] = metadata;

                // Parse categories and attributes
                for each (var categoryNode:XML in xml.category)
                {
                    var categoryName:String = categoryNode.@name.toString();

                    for each (var attrNode:XML in categoryNode.attribute)
                    {
                        attributes.push(parseAttribute(attrNode, categoryName));
                    }
                }

                // Cache and return
                _serverCache[serverName] = attributes;
                _currentServer = serverName;

                return attributes;
            }
            catch (error:Error)
            {
                trace("ItemAttributeStorage.loadServer error:", error.message);
            }
            return null;
        }

        private function parseAttribute(attrNode:XML, category:String):ItemAttribute
        {
            var attr:ItemAttribute = new ItemAttribute();
            attr.key = attrNode.@key.toString();
            attr.type = attrNode.@type.toString() || "string";
            attr.category = category;

            // Parse placement (default null)
            var placement:String = attrNode.@placement.toString();
            if (placement && placement.length > 0)
                attr.placement = placement;

            // Parse order (default MAX_VALUE)
            var orderStr:String = attrNode.@order.toString();
            if (orderStr && orderStr.length > 0)
                attr.order = parseInt(orderStr);

            // Parse values if present (comma-separated)
            var valuesStr:String = attrNode.@values.toString();
            if (valuesStr && valuesStr.length > 0)
            {
                attr.values = valuesStr.split(",");
            }

            // Parse nested attributes
            if (attrNode.attribute.length() > 0)
            {
                attr.attributes = [];
                for each (var childNode:XML in attrNode.attribute)
                {
                    attr.attributes.push(parseAttribute(childNode, category));
                }
            }

            return attr;
        }

        /**
         * Gets attributes for currently loaded server
         */
        public function getAttributes():Vector.<ItemAttribute>
        {
            if (!_currentServer)
                return null;

            return _serverCache[_currentServer] as Vector.<ItemAttribute>;
        }

        /**
         * Gets display name for a server
         */
        public function getDisplayName(serverName:String):String
        {
            if (_serverMetadata[serverName])
                return _serverMetadata[serverName].displayName;

            return serverName;
        }

        /**
         * Checks if server supports fromid/toid range optimization
         */
        public function getSupportsFromToId():Boolean
        {
            // Default to true if metadata missing (assume modern server)
            if (_currentServer && _serverMetadata[_currentServer])
                return _serverMetadata[_currentServer].supportsFromToId;

            return true;
        }

        /**
         * Gets categories for currently loaded server
         */
        public function getCategories():Array
        {
            var attrs:Vector.<ItemAttribute> = getAttributes();
            if (!attrs)
                return [];

            var categories:Dictionary = new Dictionary();
            var result:Array = [];

            for each (var attr:ItemAttribute in attrs)
            {
                if (!categories[attr.category])
                {
                    categories[attr.category] = true;
                    result.push(attr.category);
                }
            }

            return result;
        }

        /**
         * Gets all attribute keys in config order (by category).
         * This is used by ItemsXmlWriter for consistent attribute ordering.
         */
        public function getAttributeKeysInOrder():Array
        {
            var attrs:Vector.<ItemAttribute> = getAttributes();
            if (!attrs)
                return [];

            var keys:Array = [];
            for each (var attr:ItemAttribute in attrs)
            {
                collectAttributeKeys(attr, keys);
            }
            return keys;
        }

        private function collectAttributeKeys(attr:ItemAttribute, result:Array):void
        {
            result.push(attr.key);
            if (attr.attributes)
            {
                for each (var child:ItemAttribute in attr.attributes)
                {
                    collectAttributeKeys(child, result);
                }
            }
        }

        /**
         * Gets attributes that should be placed on the <item> tag.
         */
        public function getTagAttributeKeys():Array
        {
            var attrs:Vector.<ItemAttribute> = getAttributes();
            if (!attrs)
                return [];

            var result:Array = [];
            for each (var attr:ItemAttribute in attrs)
            {
                if (attr.placement == "tag")
                    result.push(attr.key);
            }
            return result;
        }

        /**
         * Gets a map of attribute priorities (order).
         * Returns: { "key": order_int }
         */
        public function getAttributePriority():Object
        {
            var attrs:Vector.<ItemAttribute> = getAttributes();
            if (!attrs)
                return {};

            var result:Object = {};
            // Helper to collect recursively
            var collect:Function = function(list:Array):void
            {
                for each (var a:ItemAttribute in list)
                {
                    if (a.order != int.MAX_VALUE)
                        result[a.key] = a.order;

                    if (a.attributes)
                        collect(a.attributes);
                }
            };

            // Convert Vector to Array for helper
            var rootList:Array = [];
            for each (var attr:ItemAttribute in attrs)
                rootList.push(attr);

            collect(rootList);

            return result;
        }

        /**
         * Gets attributes filtered by category
         */
        public function getAttributesByCategory(category:String):Vector.<ItemAttribute>
        {
            var attrs:Vector.<ItemAttribute> = getAttributes();
            if (!attrs)
                return null;

            var result:Vector.<ItemAttribute> = new Vector.<ItemAttribute>();
            for each (var attr:ItemAttribute in attrs)
            {
                if (attr.category == category)
                    result.push(attr);
            }

            return result;
        }

        /**
         * Searches attributes by key (partial match)
         */
        public function searchAttributes(keyword:String):Vector.<ItemAttribute>
        {
            var attrs:Vector.<ItemAttribute> = getAttributes();
            if (!attrs)
                return null;

            keyword = keyword.toLowerCase();
            var result:Vector.<ItemAttribute> = new Vector.<ItemAttribute>();

            for each (var attr:ItemAttribute in attrs)
            {
                if (attr.key.toLowerCase().indexOf(keyword) >= 0)
                    result.push(attr);
            }

            return result;
        }

        /**
         * Current loaded server name
         */
        public function get currentServer():String
        {
            return _currentServer;
        }
    }
}
