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
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    /**
     * Reader for items.otb files.
     * Uses Binary Tree format with escape characters.
     */
    public class OtbReader
    {
        // --------------------------------------------------------------------------
        // PROPERTIES
        // --------------------------------------------------------------------------

        private var _bytes:ByteArray;
        private var _currentNodePosition:uint;
        private var _items:ServerItemList;

        // --------------------------------------------------------------------------
        // CONSTRUCTOR
        // --------------------------------------------------------------------------

        public function OtbReader()
        {
            _items = new ServerItemList();
        }

        // --------------------------------------------------------------------------
        // GETTERS / SETTERS
        // --------------------------------------------------------------------------

        public function get items():ServerItemList
        {
            return _items;
        }

        public function get count():uint
        {
            return _items.count;
        }

        // --------------------------------------------------------------------------
        // METHODS
        // --------------------------------------------------------------------------

        /**
         * Reads an OTB file from the given path.
         * @return true if successful, false otherwise
         */
        public function read(file:File):Boolean
        {
            if (!file || !file.exists)
                return false;

            try
            {
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.READ);
                stream.endian = Endian.LITTLE_ENDIAN;

                _bytes = new ByteArray();
                _bytes.endian = Endian.LITTLE_ENDIAN;
                stream.readBytes(_bytes);
                stream.close();

                _bytes.position = 0;
                _currentNodePosition = 0;
                _items.clear();

                return parseOtb();
            }
            catch (error:Error)
            {
                trace("OtbReader error: " + error.message);
            }

            return false;
        }

        /**
         * Reads an OTB file from ByteArray.
         * @return true if successful, false otherwise
         */
        public function readFromBytes(bytes:ByteArray):Boolean
        {
            if (!bytes || bytes.length == 0)
                return false;

            try
            {
                _bytes = bytes;
                _bytes.endian = Endian.LITTLE_ENDIAN;
                _bytes.position = 0;
                _currentNodePosition = 0;
                _items.clear();

                return parseOtb();
            }
            catch (error:Error)
            {
                trace("OtbReader error: " + error.message);
            }

            return false;
        }

        // --------------------------------------------------------------------------
        // PRIVATE METHODS
        // --------------------------------------------------------------------------

        private function parseOtb():Boolean
        {
            // Get root node
            var rootNode:ByteArray = getRootNode();
            if (!rootNode)
                return false;

            rootNode.position = 0;
            rootNode.readByte(); // first byte is 0
            rootNode.readUnsignedInt(); // flags, unused

            var attr:uint = rootNode.readUnsignedByte();
            if (attr == RootAttribute.VERSION)
            {
                var datalen:uint = rootNode.readUnsignedShort();
                if (datalen != 140) // 4 + 4 + 4 + 128
                {
                    trace("Invalid version header size: " + datalen);
                    return false;
                }

                _items.majorVersion = rootNode.readUnsignedInt();
                _items.minorVersion = rootNode.readUnsignedInt();
                _items.buildNumber = rootNode.readUnsignedInt();

                // Skip 128 bytes of CSD version string
                rootNode.position += 128;
            }

            // Read child nodes (items)
            var node:ByteArray = getChildNode();
            if (!node)
                return false;

            while (node != null)
            {
                var item:ServerItem = new ServerItem();
                node.position = 0;

                // Read item group
                var itemGroup:uint = node.readUnsignedByte();
                switch (itemGroup)
                {
                    case ServerItemGroup.NONE:
                        item.type = ServerItemType.NONE;
                        break;
                    case ServerItemGroup.GROUND:
                        item.type = ServerItemType.GROUND;
                        break;
                    case ServerItemGroup.CONTAINER:
                        item.type = ServerItemType.CONTAINER;
                        break;
                    case ServerItemGroup.SPLASH:
                        item.type = ServerItemType.SPLASH;
                        break;
                    case ServerItemGroup.FLUID:
                        item.type = ServerItemType.FLUID;
                        break;
                    case ServerItemGroup.DEPRECATED:
                        item.type = ServerItemType.DEPRECATED;
                        break;
                    default:
                        item.type = ServerItemType.NONE;
                        break;
                }

                // Read flags
                var flags:uint = node.readUnsignedInt();
                item.setFlags(flags);

                // Read attributes
                while (node.bytesAvailable > 0)
                {
                    var attribute:uint = node.readUnsignedByte();
                    var attrLen:uint = node.readUnsignedShort();

                    switch (attribute)
                    {
                        case ServerItemAttribute.SERVER_ID:
                            item.id = node.readUnsignedShort();
                            break;

                        case ServerItemAttribute.CLIENT_ID:
                            item.clientId = node.readUnsignedShort();
                            break;

                        case ServerItemAttribute.GROUND_SPEED:
                            item.groundSpeed = node.readUnsignedShort();
                            break;

                        case ServerItemAttribute.NAME:
                            item.name = node.readUTFBytes(attrLen);
                            break;

                        case ServerItemAttribute.SPRITE_HASH:
                            item.spriteHash = new ByteArray();
                            node.readBytes(item.spriteHash, 0, attrLen);
                            break;

                        case ServerItemAttribute.MINIMAP_COLOR:
                            item.minimapColor = node.readUnsignedShort();
                            break;

                        case ServerItemAttribute.MAX_READ_WRITE_CHARS:
                            item.maxReadWriteChars = node.readUnsignedShort();
                            break;

                        case ServerItemAttribute.MAX_READ_CHARS:
                            item.maxReadChars = node.readUnsignedShort();
                            break;

                        case ServerItemAttribute.LIGHT:
                            item.lightLevel = node.readUnsignedShort();
                            item.lightColor = node.readUnsignedShort();
                            break;

                        case ServerItemAttribute.STACK_ORDER:
                            item.stackOrder = node.readUnsignedByte();
                            break;

                        case ServerItemAttribute.TRADE_AS:
                            item.tradeAs = node.readUnsignedShort();
                            break;

                        default:
                            // Skip unknown attribute
                            node.position += attrLen;
                            break;
                    }
                }

                // Ensure sprite hash exists for non-deprecated items
                if (!item.spriteHash && item.type != ServerItemType.DEPRECATED)
                {
                    item.spriteHash = new ByteArray();
                    item.spriteHash.length = 16;
                }

                _items.add(item);
                node = getNextNode();
            }

            return true;
        }

        private function getRootNode():ByteArray
        {
            return getChildNode();
        }

        private function getChildNode():ByteArray
        {
            if (!advance())
                return null;

            return getNodeData();
        }

        private function getNextNode():ByteArray
        {
            _bytes.position = _currentNodePosition;

            var value:uint = _bytes.readUnsignedByte();
            if (value != SpecialChar.NODE_START)
                return null;

            _bytes.readUnsignedByte(); // Skip node type

            var level:int = 1;
            while (_bytes.bytesAvailable > 0)
            {
                value = _bytes.readUnsignedByte();

                if (value == SpecialChar.NODE_END)
                {
                    level--;
                    if (level == 0)
                    {
                        if (_bytes.bytesAvailable == 0)
                            return null;

                        value = _bytes.readUnsignedByte();
                        if (value == SpecialChar.NODE_END)
                            return null;
                        else if (value != SpecialChar.NODE_START)
                            return null;
                        else
                        {
                            _currentNodePosition = _bytes.position - 1;
                            return getNodeData();
                        }
                    }
                }
                else if (value == SpecialChar.NODE_START)
                {
                    level++;
                }
                else if (value == SpecialChar.ESCAPE_CHAR)
                {
                    if (_bytes.bytesAvailable > 0)
                        _bytes.readUnsignedByte();
                }
            }

            return null;
        }

        private function getNodeData():ByteArray
        {
            _bytes.position = _currentNodePosition;

            var value:uint = _bytes.readUnsignedByte();
            if (value != SpecialChar.NODE_START)
                return null;

            var nodeData:ByteArray = new ByteArray();
            nodeData.endian = Endian.LITTLE_ENDIAN;

            while (_bytes.bytesAvailable > 0)
            {
                value = _bytes.readUnsignedByte();

                if (value == SpecialChar.NODE_END || value == SpecialChar.NODE_START)
                    break;
                else if (value == SpecialChar.ESCAPE_CHAR)
                {
                    if (_bytes.bytesAvailable > 0)
                        value = _bytes.readUnsignedByte();
                }

                nodeData.writeByte(value);
            }

            _bytes.position = _currentNodePosition;
            nodeData.position = 0;
            return nodeData;
        }

        private function advance():Boolean
        {
            try
            {
                var seekPos:uint = 0;
                if (_currentNodePosition == 0)
                    seekPos = 4; // Skip first 4 bytes (version)
                else
                    seekPos = _currentNodePosition;

                _bytes.position = seekPos;

                var value:uint = _bytes.readUnsignedByte();
                if (value != SpecialChar.NODE_START)
                    return false;

                if (_currentNodePosition == 0)
                {
                    _currentNodePosition = _bytes.position - 1;
                    return true;
                }
                else
                {
                    _bytes.readUnsignedByte(); // Skip node type

                    while (_bytes.bytesAvailable > 0)
                    {
                        value = _bytes.readUnsignedByte();

                        if (value == SpecialChar.NODE_END)
                            return false;
                        else if (value == SpecialChar.NODE_START)
                        {
                            _currentNodePosition = _bytes.position - 1;
                            return true;
                        }
                        else if (value == SpecialChar.ESCAPE_CHAR)
                        {
                            if (_bytes.bytesAvailable > 0)
                                _bytes.readUnsignedByte();
                        }
                    }
                }
            }
            catch (error:Error)
            {
                return false;
            }

            return false;
        }
    }
}
