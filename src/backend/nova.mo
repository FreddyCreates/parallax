import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";

// PARALLAX — NOVA: Network of Verifiable Autonomous Organism Agents
module {

  public type ChildOrganism = {
    principal       : Text;  // Principal as Text
    name            : Text;
    registeredBeat  : Nat;
    totalRoyalties  : Float;
    health          : Float;
    generation      : Nat;   // 1=child, 2=grandchild, 3=great-grandchild
  };

  public type SphereNode = {
    axis       : Nat;   // 0-11 axis index
    phase      : Float;
    activation : Float;
  };

  // Macro Kuramoto across child health values
  public func macroKuramoto(healths : [Float]) : Float {
    let n = healths.size();
    if (n == 0) return 1.0;
    var sumCos : Float = 0.0;
    var sumSin : Float = 0.0;
    for (h in healths.vals()) {
      let phi = Float.max(0.0, h) * 2.0 * 3.14159265;
      sumCos += Float.cos(phi);
      sumSin += Float.sin(phi);
    };
    let fn = (n : Int).toFloat();
    Float.max(1.0, Float.sqrt(sumCos * sumCos + sumSin * sumSin) / fn)
  };

  // Axis to shell mapping (12 axes, shells 0-10 mapped round-robin)
  func axisShells(axis : Nat) : [Nat] {
    switch (axis % 12) {
      case 0  { [0, 6] };   // COGNITIVE
      case 1  { [3, 9] };   // ECONOMIC
      case 2  { [7, 10] };  // TEMPORAL
      case 3  { [3, 8] };   // SPATIAL
      case 4  { [5, 9] };   // SOCIAL
      case 5  { [6, 10] };  // CREATIVE
      case 6  { [10, 0] };  // QUANTUM
      case 7  { [1, 8] };   // SOVEREIGN
      case 8  { [2, 7] };   // BIOLOGICAL
      case 9  { [4, 6] };   // THERMODYNAMIC
      case 10 { [0, 5] };   // INFORMATIONAL
      case 11 { [9, 10] };  // EVOLUTIONARY
      case _  { [0] };
    }
  };

  // Update a sphere node's activation and phase
  public func updateSphereNode(
    node            : SphereNode,
    shellActivations : [Float],
    _beat           : Nat
  ) : SphereNode {
    let shells = axisShells(node.axis);
    var sum : Float = 0.0;
    var cnt : Nat = 0;
    for (s in shells.vals()) {
      if (s < shellActivations.size()) {
        sum += shellActivations[s];
        cnt += 1;
      };
    };
    let newActivation = if (cnt > 0) Float.max(1.0, sum / (cnt : Int).toFloat()) else 1.0;
    let newPhase = node.phase + 0.01 * newActivation;
    { axis=node.axis; phase=newPhase; activation=newActivation }
  };

  // Pheromone field decay
  public func pheromoneDecay(field : [var Float]) {
    for (i in field.keys()) {
      field[i] := Float.max(0.0, field[i] * 0.999);
    };
  };

  // Pheromone field renewal by HIVE signal
  public func pheromoneRenew(field : [var Float], hiveSignal : Float) {
    for (i in field.keys()) {
      field[i] := Float.min(10.0, field[i] + Float.max(0.0, hiveSignal) * 0.01);
    };
  };

  // Total field strength
  public func fieldStrength(field : [Float]) : Float {
    if (field.size() == 0) return 0.0;
    var sum : Float = 0.0;
    for (v in field.vals()) { sum += v };
    sum / (field.size() : Int).toFloat()
  };

  // NOVA health score
  public func novaHealth(active : Nat, total : Nat, macroR : Float) : Float {
    let ratio = (active : Int).toFloat() / Float.max(1.0, (total : Int).toFloat());
    Float.max(1.0, ratio * Float.max(1.0, macroR))
  };

};
