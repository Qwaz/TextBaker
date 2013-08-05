package textbaker.events {
	import flash.events.Event;
	
	public class TextBakerEvent extends Event {
		
		public static const
		TEXT_PUSHED:String = "textPushed";

		public function TextBakerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}

	}
	
}
