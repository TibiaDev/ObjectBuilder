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
    /**
     * Server item flags as stored in items.otb
     * These are bit flags that can be combined.
     */
    public final class ServerItemFlag
    {
        public static const NONE:uint = 0;
        public static const UNPASSABLE:uint = 1 << 0;
        public static const BLOCK_MISSILES:uint = 1 << 1;
        public static const BLOCK_PATHFINDER:uint = 1 << 2;
        public static const HAS_ELEVATION:uint = 1 << 3;
        public static const MULTI_USE:uint = 1 << 4;
        public static const PICKUPABLE:uint = 1 << 5;
        public static const MOVABLE:uint = 1 << 6;
        public static const STACKABLE:uint = 1 << 7;
        public static const FLOOR_CHANGE_DOWN:uint = 1 << 8;
        public static const FLOOR_CHANGE_NORTH:uint = 1 << 9;
        public static const FLOOR_CHANGE_EAST:uint = 1 << 10;
        public static const FLOOR_CHANGE_SOUTH:uint = 1 << 11;
        public static const FLOOR_CHANGE_WEST:uint = 1 << 12;
        public static const STACK_ORDER:uint = 1 << 13;
        public static const READABLE:uint = 1 << 14;
        public static const ROTATABLE:uint = 1 << 15;
        public static const HANGABLE:uint = 1 << 16;
        public static const HOOK_EAST:uint = 1 << 17;
        public static const HOOK_SOUTH:uint = 1 << 18;
        public static const CAN_NOT_DECAY:uint = 1 << 19;
        public static const ALLOW_DISTANCE_READ:uint = 1 << 20;
        public static const UNUSED:uint = 1 << 21;
        public static const CLIENT_CHARGES:uint = 1 << 22;
        public static const IGNORE_LOOK:uint = 1 << 23;
        public static const IS_ANIMATION:uint = 1 << 24;
        public static const FULL_GROUND:uint = 1 << 25;
        public static const FORCE_USE:uint = 1 << 26;
    }
}
