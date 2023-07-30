package iterators;

class StepIterator {
	var end:Int;
	var step:Int;
	var index:Int;
	var inclusive:Bool;

	public function new(start:Int, end:Int, step:Int, ?inclusive:Bool) {
		this.index = start;
		this.end = end;
		this.step = step;
		this.inclusive = inclusive;
	}

	public function hasNext()
		return this.inclusive ? index <= end : index < end;

	public function next()
		return (index += step) - step;
}
