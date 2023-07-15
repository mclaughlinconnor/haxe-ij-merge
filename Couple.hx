class Couple<T> {
  public var left: T;
  public var right: T;

  public function new(left: T, right: T) {
    this.left = left;
    this.right = right;
  }

  @:generic
  static public function of<T>(left: T, right: T): Couple<T> {
    return new Couple(left, right);
  }
}
