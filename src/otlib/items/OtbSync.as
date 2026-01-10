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
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    import by.blooddy.crypto.MD5;

    import otlib.things.ThingType;
    import otlib.things.FrameGroupType;
    import otlib.sprites.Sprite;
    import otlib.sprites.SpriteStorage;
    import otlib.geom.Size;

    /**
     * Utility class for synchronizing flags between ThingType (tibia.dat)
     * and ServerItem (items.otb).
     *
     * This is the single source of truth for all flag mappings between
     * DAT properties and OTB properties. Mirrors item-editor behavior.
     *
     * ThingType is the source of truth for flags when editing.
     * ServerItem stores the mapping Server ID -> Client ID.
     */
    public class OtbSync
    {
        /**
         * Updates a ServerItem's flags and attributes from a ThingType.
         * Call this when "Reload Attributes" is used.
         *
         * This mirrors item-editor's ReloadItem behavior.
         * NOTE: Type is NOT synced by default - only flags.
         *
         * @param serverItem The server item to update
         * @param thingType The thing type with current flag values
         * @param syncType If true, also sync type. Use for new items only.
         * @param clientVersion The client version (e.g. 860, 1098). Used for flag filtering.
         * @param spriteStorage SpriteStorage instance for sprite hash calculation (optional)
         */
        public static function syncFromThingType(serverItem:ServerItem, thingType:ThingType, syncType:Boolean = false, clientVersion:uint = 0, spriteStorage:SpriteStorage = null):void
        {
            if (!serverItem || !thingType)
                return;

            // ------------------------------------------------------------------
            // TYPE (only sync when creating new items)
            // ------------------------------------------------------------------
            if (syncType)
            {
                if (thingType.isGround)
                {
                    serverItem.type = ServerItemType.GROUND;
                }
                else if (thingType.isContainer)
                {
                    serverItem.type = ServerItemType.CONTAINER;
                }
                else if (thingType.isFluidContainer)
                {
                    serverItem.type = ServerItemType.FLUID;
                }
                else if (thingType.isFluid)
                {
                    serverItem.type = ServerItemType.SPLASH;
                }
                else
                {
                    serverItem.type = ServerItemType.NONE;
                }
            }

            // ------------------------------------------------------------------
            // SPRITE HASH (ItemEditor parity)
            // ------------------------------------------------------------------
            // Create hash if type is not deprecated and not NONE (unless needed)
            // Only if we have the callback to get sprites
            if (spriteStorage != null && serverItem.type != ServerItemType.DEPRECATED)
            {
                serverItem.spriteHash = spriteStorage.getSpriteHash(thingType);
                serverItem.spriteAssigned = true;
            }

            // ------------------------------------------------------------------
            // FLAGS (boolean properties stored as bits in OTB)
            // ------------------------------------------------------------------
            serverItem.unpassable = thingType.isUnpassable;
            serverItem.blockMissiles = thingType.blockMissile;
            serverItem.blockPathfinder = thingType.blockPathfind;
            serverItem.hasElevation = thingType.hasElevation;
            serverItem.multiUse = thingType.multiUse;
            serverItem.pickupable = thingType.pickupable;
            serverItem.movable = !thingType.isUnmoveable; // Note: inverted!
            serverItem.stackable = thingType.stackable;
            serverItem.readable = thingType.writable || thingType.writableOnce || (thingType.isLensHelp && thingType.lensHelp == 1112);
            serverItem.rotatable = thingType.rotatable;
            serverItem.hangable = thingType.hangable;
            serverItem.hookSouth = thingType.isVertical;
            serverItem.hookEast = thingType.isHorizontal;
            serverItem.ignoreLook = thingType.ignoreLook;
            serverItem.allowDistanceRead = false; // Not stored in DAT

            // ------------------------------------------------------------------
            // VERSION-SPECIFIC FLAG FILTERING (ItemEditor Parity)
            // ------------------------------------------------------------------

            // ForceUse and FullGround:
            // ItemEditor ignores these for versions < 10.10 (PluginOne, PluginTwo).
            // It reads them for versions >= 10.10 (PluginThree).
            // Note: clientVersion 1010 means 10.10
            if (clientVersion >= 1010)
            {
                serverItem.forceUse = thingType.forceUse;
                serverItem.fullGround = thingType.isFullGround;
            }
            else
            {
                serverItem.forceUse = false;
                serverItem.fullGround = false;
            }

            // HasCharges and AnimateAlways:
            // ItemEditor ignores these in ALL plugins (One, Two, Three).
            // So we always set them to false to match OTB output.
            serverItem.hasCharges = false;
            serverItem.isAnimation = false; // ItemEditor sets this based on frames > 1, not the flag.
            // However, OTB writer checks `item.IsAnimation`.
            // ItemEditor's ServerItem sets IsAnimation flag if `ThingType.frames > 1`.
            // Let's check logic below.

            // Re-evaluating IsAnimation:
            // ItemEditor's OtbWriter: if (item.IsAnimation) flags |= ServerItemFlag.IsAnimation;
            // ItemEditor's Plugin reads: item.IsAnimation = item.Frames > 1;
            // It ignores the 'AnimateAlways' flag from DAT.
            // So we should do:
            var group:Object = thingType.getFrameGroup(FrameGroupType.DEFAULT);
            if (group && group.frames > 1)
            {
                serverItem.isAnimation = true;
            }
            else
            {
                serverItem.isAnimation = false;
            }

            // ------------------------------------------------------------------
            // ATTRIBUTES (additional data with values)
            // ------------------------------------------------------------------

            // Light
            serverItem.lightLevel = thingType.lightLevel;
            serverItem.lightColor = thingType.lightColor;

            // Ground speed (only for ground items)
            if (thingType.isGround)
            {
                serverItem.groundSpeed = thingType.groundSpeed;
            }

            // Minimap color
            serverItem.minimapColor = thingType.miniMapColor;

            // Readable chars: Writable -> maxReadWriteChars, WritableOnce -> maxReadChars
            // Readable chars: Writable -> maxReadWriteChars, WritableOnce -> maxReadChars
            if (thingType.writable)
            {
                serverItem.maxReadWriteChars = thingType.maxReadWriteChars;
            }
            else
            {
                serverItem.maxReadWriteChars = 0;
            }

            if (thingType.writableOnce)
            {
                serverItem.maxReadChars = thingType.maxReadChars;
            }
            else
            {
                serverItem.maxReadChars = 0;
            }

            // Stack order (tile rendering order)
            if (thingType.isGroundBorder)
            {
                serverItem.stackOrder = TileStackOrder.BORDER;
                serverItem.hasStackOrder = true;
            }
            else if (thingType.isOnBottom)
            {
                serverItem.stackOrder = TileStackOrder.BOTTOM;
                serverItem.hasStackOrder = true;
            }
            else if (thingType.isOnTop)
            {
                serverItem.stackOrder = TileStackOrder.TOP;
                serverItem.hasStackOrder = true;
            }
            else
            {
                serverItem.stackOrder = TileStackOrder.NONE;
                serverItem.hasStackOrder = false;
            }

            // NAME (ItemEditor parity)
            // ItemEditor maps marketName -> Name (OTB attribute 0x1D)
            if (thingType.marketName && thingType.marketName.length > 0)
            {
                serverItem.name = thingType.marketName; // OTB name, NOT nameXml
            }

            // TRADE AS (ItemEditor parity)
            if (thingType.marketTradeAs != 0)
            {
                serverItem.tradeAs = thingType.marketTradeAs;
            }
        }

        /**
         * Creates a new ServerItem from a ThingType.
         * Used when creating missing items in OTB.
         * For new items, type IS synced from ThingType.
         *
         * @param thingType The thing type to create from
         * @param serverId The server ID to assign
         * @param clientVersion The client version for flag filtering
         * @param spriteStorage SpriteStorage for hash calculation
         * @return A new ServerItem with synced flags and type
         */
        public static function createFromThingType(thingType:ThingType, serverId:uint, clientVersion:uint = 0, spriteStorage:SpriteStorage = null):ServerItem
        {
            var item:ServerItem = new ServerItem();
            item.id = serverId;
            item.clientId = thingType.id;

            // For NEW items, sync type too
            syncFromThingType(item, thingType, true, clientVersion, spriteStorage);

            return item;
        }

        /**
         * Checks if a ServerItem's flags match a ThingType's flags.
         * Only checks boolean flags (not value attributes like lightLevel).
         * Used to determine if an item needs reloading.
         *
         * @param serverItem The server item
         * @param thingType The thing type
         * @return true if all flags match
         */
        public static function flagsMatch(serverItem:ServerItem, thingType:ThingType):Boolean
        {
            if (!serverItem || !thingType)
                return false;

            // Type check
            var expectedType:uint = ServerItemType.NONE;
            if (thingType.isGround)
                expectedType = ServerItemType.GROUND;
            else if (thingType.isContainer)
                expectedType = ServerItemType.CONTAINER;
            else if (thingType.isFluidContainer)
                expectedType = ServerItemType.FLUID;
            else if (thingType.isFluid)
                expectedType = ServerItemType.SPLASH;

            if (serverItem.type != expectedType)
                return false;

            // Flag checks - matching syncFromThingType logic
            if (serverItem.unpassable != thingType.isUnpassable)
                return false;
            if (serverItem.blockMissiles != thingType.blockMissile)
                return false;
            if (serverItem.blockPathfinder != thingType.blockPathfind)
                return false;
            if (serverItem.hasElevation != thingType.hasElevation)
                return false;
            if (serverItem.multiUse != thingType.multiUse)
                return false;
            if (serverItem.pickupable != thingType.pickupable)
                return false;
            if (serverItem.movable != !thingType.isUnmoveable)
                return false;
            if (serverItem.stackable != thingType.stackable)
                return false;
            if (serverItem.readable != (thingType.writable || thingType.writableOnce || (thingType.isLensHelp && thingType.lensHelp == 1112)))
                return false;

            // Check lengths if readable
            if (thingType.writable && serverItem.maxReadWriteChars != thingType.maxReadWriteChars)
                return false;
            if (thingType.writableOnce && serverItem.maxReadChars != thingType.maxReadChars)
                return false;

            if (serverItem.rotatable != thingType.rotatable)
                return false;
            if (serverItem.hangable != thingType.hangable)
                return false;
            if (serverItem.hookEast != thingType.isHorizontal)
                return false;
            if (serverItem.hookSouth != thingType.isVertical)
                return false;
            if (serverItem.ignoreLook != thingType.ignoreLook)
                return false;

            // Flags that are always false in OTB (HasCharges)
            if (serverItem.hasCharges != false)
                return false;

            // IsAnimation derived from frames
            var group:Object = thingType.getFrameGroup(FrameGroupType.DEFAULT);
            var expectedAnim:Boolean = (group && group.frames > 1);
            if (serverItem.isAnimation != expectedAnim)
                return false;

            // Stack order (only if has stack order)
            var expectedHasStackOrder:Boolean = thingType.isGroundBorder || thingType.isOnBottom || thingType.isOnTop;
            if (serverItem.hasStackOrder != expectedHasStackOrder)
                return false;

            return true;
        }
    }
}
