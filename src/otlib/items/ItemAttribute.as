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
     * Represents a single attribute definition from server attribute XML.
     * Used for displaying available attributes in the UI.
     */
    public class ItemAttribute
    {
        // --------------------------------------------------------------------------
        // PROPERTIES
        // --------------------------------------------------------------------------

        /** Attribute key name, e.g., "attack", "defense", "weight" */
        public var key:String;

        /** Value type: "string", "number", "boolean", "mixed" (dropdown + text) */
        public var type:String;

        /** Category this attribute belongs to, e.g., "General", "Combat" */
        public var category:String;

        /** Attribute placement: "tag" or default (nested) */
        public var placement:String;

        /** Sort order (lower comes first). Default: int.MAX_VALUE (unordered) */
        public var order:int;

        /** Predefined values for dropdown (e.g., slotType: feet, armor, legs) */
        public var values:Array;

        /** Nested attributes schema */
        public var attributes:Array;

        // --------------------------------------------------------------------------
        // CONSTRUCTOR
        // --------------------------------------------------------------------------

        public function ItemAttribute(key:String = "", type:String = "string", category:String = "General", values:Array = null, placement:String = null, order:int = int.MAX_VALUE)
        {
            this.key = key;
            this.type = type;
            this.category = category;
            this.values = values;
            this.placement = placement;
            this.order = order;
        }

        // --------------------------------------------------------------------------
        // PUBLIC METHODS
        // --------------------------------------------------------------------------

        /**
         * Returns a string representation for debugging
         */
        public function toString():String
        {
            return "[ItemAttribute key=" + key + " type=" + type + " category=" + category + " placement=" + placement + " order=" + order + "]";
        }

        /**
         * Creates a copy of this attribute
         */
        public function clone():ItemAttribute
        {
            var copy:ItemAttribute = new ItemAttribute(key, type, category, values ? values.slice() : null, placement, order);
            return copy;
        }
    }
}
