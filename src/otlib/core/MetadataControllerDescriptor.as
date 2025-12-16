package otlib.core
{
    /**
     * Describes a metadata controller (reader/writer pair).
     * For custom controllers, readerClass/writerClass point to custom implementations.
     * For "Default", these are null and version-based selection is used.
     */
    public class MetadataControllerDescriptor
    {
        public var name:String;
        public var readerClass:Class;
        public var writerClass:Class;

        public function MetadataControllerDescriptor(name:String, readerClass:Class = null, writerClass:Class = null)
        {
            this.name = name;
            this.readerClass = readerClass;
            this.writerClass = writerClass;
        }

        public function toString():String
        {
            return name;
        }
    }
}
