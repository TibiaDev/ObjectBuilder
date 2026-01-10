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

package otlib.utils
{
    import flash.display.BitmapData;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import nail.errors.AbstractClassError;
    import nail.utils.BitmapUtil;

    import otlib.assets.Assets;

    public final class SpriteUtils
    {
        // --------------------------------------------------------------------------
        // CONSTRUCTOR
        // --------------------------------------------------------------------------

        public function SpriteUtils()
        {
            throw new AbstractClassError(SpriteUtils);
        }

        // --------------------------------------------------------------------------
        // STATIC
        // --------------------------------------------------------------------------
        private static const POINT:Point = new Point();
        private static const DEFAULT_RECT:Rectangle = new Rectangle(0, 0, SpriteExtent.DEFAULT_SIZE, SpriteExtent.DEFAULT_SIZE);

        // Cached alert bitmaps (lazy initialized)
        private static var _alert32:BitmapData;
        private static var _alert64:BitmapData;
        private static var _alert128:BitmapData;
        private static var _alert256:BitmapData;

        public static function fillBackground(sprite:BitmapData):BitmapData
        {
            var bitmap:BitmapData = new BitmapData(SpriteExtent.DEFAULT_SIZE, SpriteExtent.DEFAULT_SIZE, false, 0xFF00FF);
            bitmap.copyPixels(sprite, DEFAULT_RECT, POINT, null, null, true);
            return bitmap;
        }

        public static function removeMagenta(sprite:BitmapData):BitmapData
        {
            // Transform bitmap 24 to 32 bits
            if (!sprite.transparent)
            {
                sprite = BitmapUtil.to32bits(sprite);
            }

            // Replace magenta to transparent.
            BitmapUtil.replaceColor(sprite, 0xFFFF00FF, 0x00FF00FF);
            return sprite;
        }

        public static function isEmpty(sprite:BitmapData):Boolean
        {
            var bounds:Rectangle = sprite.getColorBoundsRect(0xFF000000, 0x00000000, false);
            if (bounds.width == 0 && bounds.height == 0)
                return true;
            return false;
        }

        public static function createAlertBitmap():BitmapData
        {
            var data:BitmapData;
            switch (SpriteExtent.DEFAULT_SIZE)
            {
                case 32:
                    if (!_alert32)
                        _alert32 = (new Assets.ALERT_IMAGE32).bitmapData;
                    data = _alert32;
                    break;

                case 64:
                    if (!_alert64)
                        _alert64 = (new Assets.ALERT_IMAGE64).bitmapData;
                    data = _alert64;
                    break;

                case 128:
                    if (!_alert128)
                        _alert128 = (new Assets.ALERT_IMAGE128).bitmapData;
                    data = _alert128;
                    break;

                case 256:
                    if (!_alert256)
                        _alert256 = (new Assets.ALERT_IMAGE256).bitmapData;
                    data = _alert256;
                    break;

                default:
                    if (!_alert32)
                        _alert32 = (new Assets.ALERT_IMAGE32).bitmapData;
                    data = _alert32;
                    break;
            }

            return data;
        }
    }
}
