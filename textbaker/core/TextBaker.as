package textbaker.core {
	import flash.events.EventDispatcher;
	import flash.text.TextField;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	import textbaker.events.StateChangeEvent;
	import textbaker.events.TextBakerEvent;
	
	public class TextBaker extends EventDispatcher {
		
		private var _textField:TextField;
		
		private var _state:int, _index:int = -1;
		private var _timer:Timer;
		
		private var _textQueue:Vector.<String>;
		
		public var context:Object;
		private var _effects:Object;

		public function TextBaker(textField:TextField, delay:Number=50) {
			//초기화 블럭
			_textField = textField;
			
			_state = TextBakerState.WAIT;
			
			_textQueue = new Vector.<String>();
			
			context = {};
			_effects = {};
			
			_timer = new Timer(delay);
			_timer.addEventListener(TimerEvent.TIMER, timerHandler);
		}
		
		//state 변수 처리 관련
		public function get state():int {
			return _state;
		}
		
		public function set state(targetState:int):void {
			//StateChangeEvent 발생
			if(_state != targetState){
				var stateChangeEvent:StateChangeEvent = new StateChangeEvent(StateChangeEvent.STATE_CHANGE);
				stateChangeEvent.prevState = _state;
				stateChangeEvent.nextState = targetState;
				this.dispatchEvent(stateChangeEvent);
				_state = targetState;
			}
		}
		
		//이펙트 추가/제거
		public function addEffect(name:String, target:Function):void {
			_effects[name] = target;
		}
		
		public function removeEffect(name:String):void {
			delete _effects[name];
		}
		
		//문자열 추가 관련 함수
		public function push(target:String):void {
			_textQueue.push(target);
			this.dispatchEvent(new TextBakerEvent(TextBakerEvent.TEXT_PUSHED));
		}
		
		public function pushArray(target:Array):void {
			for each (var item:String in target){
				_textQueue.push(item);
			}
			this.dispatchEvent(new TextBakerEvent(TextBakerEvent.TEXT_PUSHED));
		}
		
		public function next():void {
			if(_state == TextBakerState.PLAYING){
				skip();
			} else if(_state == TextBakerState.END){
				_textQueue.shift();
				_index = -1;
				_textField.text = "";
				start();
			} else {
				start();
			}
		}
		
		public function start():void {
			if(_textQueue.length > 0){
				_timer.start();
				state = TextBakerState.PLAYING;
			} else {
				state = TextBakerState.WAIT;
			}
		}
		
		public function stop():void {
			_timer.stop();
			state = TextBakerState.STOP;
		}
		
		private function skip():void {
			while(state != TextBakerState.END){
				nextStep();
			}
		}
		
		private function timerHandler(e:TimerEvent):void {
			nextStep();
		}
		
		//변수 replace 관련 함수
		private function parseContext(...args):String {
			var rawText:String = args[2];
			var splitted:Array = rawText.split('.');
			
			var now:Object = context;
			try {
				for each(var str:String in splitted){
					now = now[str];
				}
			
				return args[1]+now.toString();
			} catch(e:Error){
				trace(e.errorID+" : "+e.message+" / "+str);
				//TODO Error 리턴
			}
			
			//파싱 에러 발생 시 문자열 그대로 출력
			return args[args.length-1];
		}
		
		//다음 글자 출력
		private function nextStep():void {
			if(_index == -1){
				//변수 replace
				_textQueue[0] = _textQueue[0].replace(/([^\\]|^)\[\s*(\S+)?\s*\]/g, parseContext);
				_index = 0;
			}
			
			while(_index < _textQueue[0].length){
				var firstChar:String = _textQueue[0].substr(_index, 1);
				
				if(firstChar == '{'){
					//이펙트 호출
					var lastIndex:int = _textQueue[0].indexOf('}', _index);
					
					var rawText:String = _textQueue[0].substring(_index+1, lastIndex).replace(/ /g, "");
					var splitted:Array = rawText.split(":");
					
					var args:Array;
					if(splitted.length == 1){
						args = [];
					} else {
						//아규먼트 설정
						args = splitted[1].split(",");
						
						var i:int;
						for(i=0; i<args.length; i++){
							if(!isNaN(Number(args[i]))){
								args[i] = Number(args[i]);
							}
						}
					}
					
					//이펙트 호출
					_effects[splitted[0]].apply(null, args);
					
					_index = lastIndex+1;
				} else if(firstChar == '\\'){
					_index++;
					//TODO 문자열 출력 이벤트 발생
					_textField.appendText(_textQueue[0].substr(_index++, 1));
					
					break;
				} else {
					//TODO 문자열 출력 이벤트 발생
					_index++;
					_textField.appendText(firstChar);
					
					break;
				}
			}
			
			if(_index == _textQueue[0].length){
				state = TextBakerState.END;
				_timer.reset();
			}
		}
	}
}
