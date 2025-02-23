package com.whirled.contrib.avrg.debug.fakeavrg
{
    import com.threerings.util.ArrayUtil;
    import com.whirled.AbstractControl;
    import com.whirled.avrg.AVRGameAvatar;
    import com.whirled.avrg.RoomSubControlClient;
    import com.whirled.net.PropertyGetSubControl;

    public class RoomSubControlClientFake extends RoomSubControlClient
    {
        public function RoomSubControlClientFake(ctrl:AbstractControl, targetId:int=0)
        {
            super(ctrl, targetId);
        }

        /**
         * Accesses the read-only properties associated with this room. To change properties use your
         * server agent's <code>RoomSubControlServer</code>'s <code>props</code>.
         * @see RoomSubControlServer#props
         */
        override public function get props () :PropertyGetSubControl
        {
            return _propsfake;
        }

        override public function getPlayerIds () :Array
        {
            return FakeAVRGContext.playerIds;
        }

        override public function getEntityIds (type :String = null) :Array
        {
            return FakeAVRGContext.entityIds;
        }

        /**
         * Looks up and returns the specified property for the specified entity.
         * Returns null if the entity does not exist or the entity has no such property.
         */
        override public function getEntityProperty (key :String, entityId :String = null) :Object
        {
            var index :int = ArrayUtil.indexOf(FakeAVRGContext.entityIds, entityId);
            return FakeAVRGContext.playerIds[index];
        }



        /** @private */
        override protected function createSubControls () :Array
        {
            _propsfake = new PropertySubControlFake(this, 0);
            return [ _propsfake ];
        }

        override public function setUserProps (o :Object) :void
        {
        }

        override public function getAvatarInfo(playerId :int) :AVRGameAvatar
        {
            var avatar :AVRGameAvatar = new AVRGameAvatar();
            avatar.x = 100;
            avatar.y = 100;
            avatar.z = 100;
            return avatar;

        }


        /** @private */
        protected var _propsfake :PropertySubControlFake;

    }
}
