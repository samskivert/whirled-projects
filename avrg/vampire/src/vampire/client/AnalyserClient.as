package vampire.client
{
import com.threerings.util.Log;
import com.threerings.flashbang.GameObject;
import com.whirled.net.MessageReceivedEvent;

import flash.utils.ByteArray;

import mx.utils.Base64Encoder;

import vampire.data.Lineage;
import vampire.net.messages.StatsMsg;

public class AnalyserClient extends GameObject
{
    public function AnalyserClient()
    {
        registerListener(ClientContext.ctrl.player, MessageReceivedEvent.MESSAGE_RECEIVED,
            handleMessageReceived);
    }
    protected function handleMessageReceived (e :MessageReceivedEvent) :void
    {
        if (e.name == StatsMsg.NAME) {
            var msg :StatsMsg = ClientContext.msg.deserializeMessage(StatsMsg.NAME,
                e.value as ByteArray) as StatsMsg;
            if (msg == null) {
                log.error("handleMessageReceived, cannot convert to StatsMsg", "e", e);
                return;
            }
            var s :String;
            var bytes :ByteArray;
            switch (msg.type) {
                case StatsMsg.TYPE_STATS:
                bytes = msg.data;
                bytes.uncompress();
                s = bytes.readUTF();
                trace(s);
                break;

                case StatsMsg.TYPE_LINEAGE:
                bytes = msg.data;
                var enc :Base64Encoder = new Base64Encoder();
                enc.insertNewLines = false;
                enc.encodeBytes(bytes);
                s = enc.toString();
                trace("Lineage (base64 encoded and compressed)");
                trace(s);
                trace("\n");

                var ln :Lineage = new Lineage();
                bytes.uncompress();
                ln.fromBytes(bytes);
                trace("\Lineage:");
                trace(ln);
                break;
            }
        }
    }

    protected static const log :Log = Log.getLog(AnalyserClient);
}
}
