Require Import Equations.Prop.Subterm Equations.Prop.DepElim.
From Equations Require Import Equations.

Unset Equations With Funext.

Parameter size : forall {A}, list A -> nat.

Equations test (s : list bool) : list bool by wf (size s) lt:=
  test pn with true => {
  | true := nil;
  | false := nil }.