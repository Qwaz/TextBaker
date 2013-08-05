package textbaker.events {
	import flash.events.Event;
	
	public class StateChangeEvent extends Event {
		
		public static const
		STATE_CHANGE:String = "stateChange";
		
		public var prevState:int, nextState:int;

		public function StateChangeEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}

	}
	
}
