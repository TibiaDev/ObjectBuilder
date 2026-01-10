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
     * Writer for items.otb files.
     * Uses Binary Tree format with escape characters.
     */
    public class OtbWriter
    {
        // --------------------------------------------------------------------------
        // PROPERTIES
        // --------------------------------------------------------------------------

        private var _items:ServerItemList;
        private var _bytes:ByteArray;

        // --------------------------------------------------------------------------
        // CONSTRUCTOR
        // --------------------------------------------------------------------------

        public function OtbWriter(items:ServerItemList)
        {
            if (!items)
                throw new ArgumentError("items cannot be null");

            _items = items;
        }

        // --------------------------------------------------------------------------
        // METHODS
        // --------------------------------------------------------------------------

        /**
         * Writes the OTB file to the given path using temp file for safety.
         * @return true if successful, false otherwise
         */
        public function write(file:File):Boolean
        {
            var tempFile:File = new File(file.nativePath + ".tmp");

            try
            {
                _bytes = new ByteArray();
                _bytes.endian = Endian.LITTLE_ENDIAN;

                // Write header (version = 0)
                writeUInt32(0, false);

                // Create root node
                createNode(0);
                writeUInt32(0, true); // flags, unused

                // Write version info
                var versionData:ByteArray = new ByteArray();
                versionData.endian = Endian.LITTLE_ENDIAN;
                versionData.writeUnsignedInt(_items.majorVersion);
                versionData.writeUnsignedInt(_items.minorVersion);
                versionData.writeUnsignedInt(_items.buildNumber);

                // CSD version string (128 bytes)
                var csdVersion:String = "OTB " + _items.majorVersion + "." + _items.minorVersion + "." + _items.buildNumber + "-" +
                    int(_items.clientVersion / 100) + "." + (_items.clientVersion % 100);
                var csdBytes:ByteArray = new ByteArray();
                csdBytes.writeUTFBytes(csdVersion);
                csdBytes.length = 128; // Pad to 128 bytes

                versionData.writeBytes(csdBytes);

                writeProp(RootAttribute.VERSION, versionData);

                // Write each item
                var itemsArray:Array = _items.toArray();
                for each (var item:ServerItem in itemsArray)
                {
                    writeItem(item);
                }

                // Close root node
                closeNode();

                // Write to temp file first
                var stream:FileStream = new FileStream();
                stream.open(tempFile, FileMode.WRITE);
                stream.writeBytes(_bytes);
                stream.close();

                // If original exists, delete it
                if (file.exists)
                {
                    file.deleteFile();
                }

                // Move temp to target
                tempFile.moveTo(file);

                return true;
            }
            catch (error:Error)
            {
                trace("OtbWriter error: " + error.message);

                // Clean up temp file on error
                try
                {
                    if (tempFile.exists)
                        tempFile.deleteFile();
                }
                catch (e:Error)
                {
                }

                return false;
            }

            return true;
        }

        /**
         * Writes the OTB to a ByteArray.
         * @return The ByteArray containing the OTB data, or null on error
         */
        public function writeToBytes():ByteArray
        {
            try
            {
                _bytes = new ByteArray();
                _bytes.endian = Endian.LITTLE_ENDIAN;

                // Write header (version = 0)
                writeUInt32(0, false);

                // Create root node
                createNode(0);
                writeUInt32(0, true); // flags, unused

                // Write version info
                var versionData:ByteArray = new ByteArray();
                versionData.endian = Endian.LITTLE_ENDIAN;
                versionData.writeUnsignedInt(_items.majorVersion);
                versionData.writeUnsignedInt(_items.minorVersion);
                versionData.writeUnsignedInt(_items.buildNumber);

                // CSD version string (128 bytes)
                var csdVersion:String = "OTB " + _items.majorVersion + "." + _items.minorVersion + "." + _items.buildNumber + "-" +
                    int(_items.clientVersion / 100) + "." + (_items.clientVersion % 100);
                var csdBytes:ByteArray = new ByteArray();
                csdBytes.writeUTFBytes(csdVersion);
                csdBytes.length = 128;

                versionData.writeBytes(csdBytes);

                writeProp(RootAttribute.VERSION, versionData);

                // Write each item
                var itemsArray:Array = _items.toArray();
                for each (var item:ServerItem in itemsArray)
                {
                    writeItem(item);
                }

                // Close root node
                closeNode();

                _bytes.position = 0;
                return _bytes;
            }
            catch (error:Error)
            {
                trace("OtbWriter error: " + error.message);
                return null;
            }

            return null;
        }

        // --------------------------------------------------------------------------
        // PRIVATE METHODS
        // --------------------------------------------------------------------------

        private function writeItem(item:ServerItem):void
        {
            // Create node with item group
            createNode(item.getGroup());

            // Write flags
            writeUInt32(item.getFlags(), true);

            // Write attributes
            var attrData:ByteArray = new ByteArray();
            attrData.endian = Endian.LITTLE_ENDIAN;

            // Always write Server ID
            attrData.writeShort(item.id);
            writeProp(ServerItemAttribute.SERVER_ID, attrData);

            if (item.type != ServerItemType.DEPRECATED)
            {
                // Client ID
                attrData.writeShort(item.clientId);
                writeProp(ServerItemAttribute.CLIENT_ID, attrData);

                // Sprite hash
                if (item.spriteHash && item.spriteHash.length > 0)
                {
                    item.spriteHash.position = 0;
                    attrData.writeBytes(item.spriteHash);
                    writeProp(ServerItemAttribute.SPRITE_HASH, attrData);
                }

                // Minimap color
                if (item.minimapColor != 0)
                {
                    attrData.writeShort(item.minimapColor);
                    writeProp(ServerItemAttribute.MINIMAP_COLOR, attrData);
                }

                // Max read/write chars
                if (item.maxReadWriteChars != 0)
                {
                    attrData.writeShort(item.maxReadWriteChars);
                    writeProp(ServerItemAttribute.MAX_READ_WRITE_CHARS, attrData);
                }

                // Max read chars
                if (item.maxReadChars != 0)
                {
                    attrData.writeShort(item.maxReadChars);
                    writeProp(ServerItemAttribute.MAX_READ_CHARS, attrData);
                }

                // Light
                if (item.lightLevel != 0 || item.lightColor != 0)
                {
                    attrData.writeShort(item.lightLevel);
                    attrData.writeShort(item.lightColor);
                    writeProp(ServerItemAttribute.LIGHT, attrData);
                }

                // Ground speed
                if (item.type == ServerItemType.GROUND)
                {
                    attrData.writeShort(item.groundSpeed);
                    writeProp(ServerItemAttribute.GROUND_SPEED, attrData);
                }

                // Stack order
                if (item.stackOrder != TileStackOrder.NONE)
                {
                    attrData.writeByte(item.stackOrder);
                    writeProp(ServerItemAttribute.STACK_ORDER, attrData);
                }

                // Trade as
                if (item.tradeAs != 0)
                {
                    attrData.writeShort(item.tradeAs);
                    writeProp(ServerItemAttribute.TRADE_AS, attrData);
                }

                // Name
                if (item.name && item.name.length > 0)
                {
                    attrData.writeUTFBytes(item.name);
                    writeProp(ServerItemAttribute.NAME, attrData);
                }
            }

            closeNode();
        }

        private function createNode(type:uint):void
        {
            writeByte(SpecialChar.NODE_START, false);
            writeByte(type, true);
        }

        private function closeNode():void
        {
            writeByte(SpecialChar.NODE_END, false);
        }

        private function writeProp(attr:uint, data:ByteArray):void
        {
            data.position = 0;
            var bytes:ByteArray = new ByteArray();
            bytes.endian = Endian.LITTLE_ENDIAN;
            data.readBytes(bytes);
            data.position = 0;
            data.length = 0;

            writeByte(attr, true);
            writeUInt16(bytes.length, true);
            writeBytes(bytes, true);
        }

        private function writeByte(value:uint, escape:Boolean):void
        {
            if (escape && (value == SpecialChar.NODE_START || value == SpecialChar.NODE_END || value == SpecialChar.ESCAPE_CHAR))
            {
                _bytes.writeByte(SpecialChar.ESCAPE_CHAR);
            }
            _bytes.writeByte(value);
        }

        private function writeUInt16(value:uint, escape:Boolean):void
        {
            var bytes:ByteArray = new ByteArray();
            bytes.endian = Endian.LITTLE_ENDIAN;
            bytes.writeShort(value);
            bytes.position = 0;
            writeBytes(bytes, escape);
        }

        private function writeUInt32(value:uint, escape:Boolean):void
        {
            var bytes:ByteArray = new ByteArray();
            bytes.endian = Endian.LITTLE_ENDIAN;
            bytes.writeUnsignedInt(value);
            bytes.position = 0;
            writeBytes(bytes, escape);
        }

        private function writeBytes(bytes:ByteArray, escape:Boolean):void
        {
            bytes.position = 0;
            while (bytes.bytesAvailable > 0)
            {
                var b:uint = bytes.readUnsignedByte();
                writeByte(b, escape);
            }
        }
    }
}
