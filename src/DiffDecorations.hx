#if js
import js.html.VisualViewport;
import js.Browser.window;
import js.html.Element;
import js.html.svg.PolygonElement;
import js.html.svg.SVGElement;
import js.Browser.document;

class DiffDecorations {
	private static function bucketDiffTextElements():Map<Int, Array<Element>> {
		var elements = document.querySelectorAll('[data-index]');
		var buckets:Map<Int, Array<Element>> = [];

		for (element in elements) {
			var el = cast(element, Element);
			var val = Std.parseInt(el.getAttribute('data-index'));
			if (!buckets.exists(val)) {
				buckets[val] = [];
			}
			buckets[val].push(el);
		}

		return buckets;
	}

	private static function createSvgElement(n:String):SVGElement {
		return cast(document.createElementNS("http://www.w3.org/2000/svg", n));
	}

	private static function drawSvgBox(nodes:Array<Element>):js.html.svg.SVGElement {
		var svg = createSvgElement("svg");
		var elementsToAppend:Array<PolygonElement> = [];
		var viewport:VisualViewport = js.Syntax.code("window.visualViewport");
		var viewportX = viewport.pageLeft;
		var viewportY = viewport.pageTop;
		var index = 0;

		while (index < nodes.length - 1) {
			var p = cast(createSvgElement("polygon"), PolygonElement);

			var aRect = nodes[index].getBoundingClientRect();
			var aBottom = aRect.bottom + viewportY;
			// var aLeft = aRect.x + viewportX;
			var aRight = aRect.right + viewportX;
			var aTop = aRect.y + viewportY;

			var bRect = nodes[index + 1].getBoundingClientRect();
			var bBottom = bRect.bottom + viewportY;
			var bLeft = bRect.x + viewportX;
			// var bRight = bRect.right + viewportY;
			var bTop = bRect.y + viewportY;

			var one = svg.createSVGPoint();
			one.x = aRight;
			one.y = aTop;

			p.points.appendItem(one);

			var two = svg.createSVGPoint();
			two.x = bLeft;
			two.y = bTop;

			p.points.appendItem(two);

			var three = svg.createSVGPoint();
			three.x = bLeft;
			three.y = bBottom;

			p.points.appendItem(three);

			var four = svg.createSVGPoint();
			four.x = aRight;
			four.y = aBottom;

			p.points.appendItem(four);

			if (nodes[index].style.backgroundColor != "") {
				p.setAttribute("fill", nodes[index].style.backgroundColor);
			} else if (nodes[index].style.borderColor != "") {
				p.setAttribute("fill", nodes[index].style.borderColor);
			}

			p.style.opacity = "50%";

			elementsToAppend.push(p);

			index++;
		}

		for (element in elementsToAppend) {
			svg.appendChild(element);
		}

		svg.setAttribute("style", "position: absolute; top: 0; left: 0; right: 0; bottom: 0; width: 100%; height: 100%");

		return svg;
	}

	public static function decorate() {
		var existing = document.getElementById('diff-separators');
		if (existing != null) {
			existing.remove();
		}

		var rows = bucketDiffTextElements();
		var viewportX = window.scrollX;
		var elementsToAppend:Array<js.html.svg.SVGElement> = [];

		for (row in rows) {
			row.sort((a, b) -> {
				var aRect = a.getBoundingClientRect();
				var bRect = b.getBoundingClientRect();

				var aLeft = viewportX + aRect.left;
				var bLeft = viewportX + bRect.left;

				return Std.int(aLeft) - Std.int(bLeft);
			});

			elementsToAppend.push(drawSvgBox(row));
		}

		var div = document.createDivElement();
		div.setAttribute("id", "diff-separators");
		div.setAttribute("style", "position: absolute; top: 0;left: 0;right: 0; bottom: 0; pointer-events: none;");
		for (element in elementsToAppend) {
			div.appendChild(element);
		}
		document.body.appendChild(div);
	}
}
#end
