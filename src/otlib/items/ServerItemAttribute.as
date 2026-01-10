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
     * Server item attribute types as stored in items.otb
     */
    public final class ServerItemAttribute
    {
        public static const SERVER_ID:uint = 0x10;
        public static const CLIENT_ID:uint = 0x11;
        public static const NAME:uint = 0x12;
        public static const GROUND_SPEED:uint = 0x14;
        public static const SPRITE_HASH:uint = 0x20;
        public static const MINIMAP_COLOR:uint = 0x21;
        public static const MAX_READ_WRITE_CHARS:uint = 0x22;
        public static const MAX_READ_CHARS:uint = 0x23;
        public static const LIGHT:uint = 0x2A;
        public static const STACK_ORDER:uint = 0x2B;
        public static const TRADE_AS:uint = 0x2D;
    }
}
