(** ** POPLMark 1a solution

  Original development by Rafaël Bocquet: POPLmark part 1A with
  inductive definition of scope and well-scoped variables (and terms,
  types and environments). *)

Require Import Program.
Require Import Equations.Equations.
Require Import Coq.Classes.EquivDec.
Require Import Arith.

Definition scope := nat.
Inductive var : scope -> Set :=
| FO : forall {n}, var (S n)
| FS : forall {n}, var n -> var (S n)
.
Derive Signature NoConfusion NoConfusionHom for var.

Inductive scope_le : scope -> scope -> Set :=
(* We use an equality in the constructor here to avoid requiring UIP on [nat]. *)
| scope_le_n : forall {n m}, n = m -> scope_le n m
| scope_le_S : forall {n m}, scope_le n m -> scope_le n (S m)
| scope_le_map : forall {n m}, scope_le n m -> scope_le (S n) (S m).

Derive Signature NoConfusion NoConfusionHom Subterm for scope_le.

Equations scope_le_app {a b c} (p : scope_le a b) (q : scope_le b c) : scope_le a c :=
  (* by wf (signature_pack q) scope_le_subterm := *)
scope_le_app p (scope_le_n eq_refl) := p;
scope_le_app p (scope_le_S q) := scope_le_S (scope_le_app p q);
scope_le_app p (scope_le_map q) with p :=
{ | scope_le_n eq_refl := scope_le_map q;
  | scope_le_S p' := scope_le_S (scope_le_app p' q);
  | (scope_le_map p') := scope_le_map (scope_le_app p' q) }.
(* Proof. all:repeat constructor. Defined. *)

Lemma scope_le_app_len n m (q : scope_le n m) : scope_le_app (scope_le_n eq_refl) q = q.
Proof.
  depind q; simp scope_le_app; trivial. destruct e; reflexivity. now rewrite IHq.
Qed.
Hint Rewrite scope_le_app_len : scope_le_app.

Inductive type : scope -> Type :=
| tvar : forall {n}, var n -> type n
| ttop : forall {n}, type n
| tarr : forall {n}, type n -> type n -> type n
| tall : forall {n}, type n -> type (S n) -> type n
.
Derive Signature NoConfusion NoConfusionHom for type.

Inductive env : scope -> scope -> Set :=
| empty : forall {n m}, n = m -> env n m
| cons : forall {n m}, type m -> env n m -> env n (S m)
.
Derive Signature NoConfusion NoConfusionHom for env.

Lemma env_scope_le : forall {n m}, env n m -> scope_le n m.
Proof. intros n m Γ; depind Γ. constructor; auto. constructor 2; auto. Defined.

Equations env_app {a b c} (Γ : env a b) (Δ : env b c) : env a c :=
env_app Γ (empty eq_refl)      := Γ;
env_app Γ (cons t Δ) := cons t (env_app Γ Δ).

Lemma cons_app : forall {a b c} (Γ : env a b) (Δ : env b c) t, cons t (env_app Γ Δ) = env_app Γ (cons t Δ).
Proof. intros. autorewrite with env_app. reflexivity. Qed.
Hint Rewrite @cons_app.

Equations map_var {n m} (f : var n -> var m) (t : var (S n)) : var (S m) :=
map_var f FO     := FO;
map_var f (FS x) := FS (f x).

Lemma map_var_a : forall {n m o} f g a, @map_var n o (fun t => f (g t)) a = @map_var m o f (@map_var n m g a).
Proof. depind a; autorewrite with map_var; auto. Qed.

Lemma map_var_b : forall {n m} (f g : var n -> var m), (forall x, f x = g x) ->
   forall a, map_var f a = map_var g a.
Proof. depind a; autorewrite with map_var; try f_equal; auto. Qed.

Equations lift_var_by {n m} (p : scope_le n m) :  var n -> var m :=
lift_var_by (scope_le_n eq_refl)       := fun t => t;
lift_var_by (scope_le_S p)   := fun t => FS (lift_var_by p t);
lift_var_by (scope_le_map p) := map_var (lift_var_by p).

Equations lift_type_by {n m} (f : scope_le n m) (t : type n) : type m :=
lift_type_by f (tvar x)   := tvar (lift_var_by f x);
lift_type_by f ttop       := ttop;
lift_type_by f (tarr a b) := tarr (lift_type_by f a) (lift_type_by f b);
lift_type_by f (tall a b) := tall (lift_type_by f a) (lift_type_by (scope_le_map f) b).

Lemma lift_var_by_app : forall {b c} (p : scope_le b c) {a} (q : scope_le a b) t,
                          lift_var_by p (lift_var_by q t) = lift_var_by (scope_le_app q p) t.
Proof with autorewrite with lift_var_by map_var scope_le_app in *; auto.
  intros b c p; induction p; intros a q t; try destruct e...
  - rewrite IHp; auto.
  - generalize dependent p. generalize dependent t.
    depind q; subst; intros...
    rewrite IHp...
    specialize (IHp _ q).
    rewrite (map_var_b (lift_var_by (scope_le_app q p)) (fun t => lift_var_by p (lift_var_by q t))); eauto.
    rewrite <- map_var_a; auto.
Qed.
Hint Rewrite @lift_var_by_app : lift_var_by.

Lemma lift_type_by_id : forall {n} (t : type n) P, (forall x, lift_var_by P x = x) -> lift_type_by P t = t.
Proof.
  depind t; intros; autorewrite with lift_type_by; rewrite ?H, ?IHt1, ?IHt2; auto.
  intros; depelim x; autorewrite with lift_var_by map_var; try f_equal; auto.
Qed.

Lemma lift_type_by_n : forall {n} (t : type n), lift_type_by (scope_le_n eq_refl) t = t.
Proof. intros; eapply lift_type_by_id; intros; autorewrite with lift_var_by; auto. Qed.
Hint Rewrite @lift_type_by_n : lift_type_by.

Lemma lift_type_by_app : forall {a} t {b c} (p : scope_le b c) (q : scope_le a b),
                           lift_type_by p (lift_type_by q t) = lift_type_by (scope_le_app q p) t.
Proof.
  depind t; intros b c p; depind p; intros q;
  repeat (autorewrite with scope_le_app lift_var_by lift_type_by;
          rewrite ?IHt1, ?IHt2; auto).
Qed.
Hint Rewrite @lift_type_by_app : lift_type_by.

Equations lookup {n} (Γ : env O n) (x : var n) : type n :=
lookup (n:=(S _)) (cons a Γ) FO     := lift_type_by (scope_le_S (scope_le_n eq_refl)) a;
lookup (n:=(S _)) (cons a Γ) (FS x) := lift_type_by (scope_le_S (scope_le_n eq_refl)) (lookup Γ x)
.

Lemma lookup_app {n} (Γ : env O (S n)) {m} (Δ : env (S n) (S m)) x :
  lookup (env_app Γ Δ) (lift_var_by (env_scope_le Δ) x) =
  lift_type_by (env_scope_le Δ) (lookup Γ x).
Proof with autorewrite with lookup scope_le_app env_app lift_var_by lift_type_by; auto.
  induction Δ; subst; simpl...
  rewrite IHΔ... 
Qed.
Hint Rewrite @lookup_app : lookup.

(** The subtyping judgment *)

Inductive sa : forall {n}, env O n -> type n -> type n -> Prop :=
| sa_top : forall {n} (Γ : env O n) s, sa Γ s ttop
| sa_var_refl : forall {n} (Γ : env O n) x, sa Γ (tvar x) (tvar x)
| sa_var_trans : forall {n} (Γ : env O (S n)) x t,
                   sa Γ (lookup Γ x) t ->
                   sa Γ (tvar x) t
| sa_arr : forall {n} {Γ : env O n} {t1 t2 s1 s2},
             sa Γ t1 s1 ->
             sa Γ s2 t2 ->
             sa Γ (tarr s1 s2) (tarr t1 t2)
| sa_all : forall {n} {Γ : env O n} {t1 t2 s1 s2},
             sa Γ t1 s1 ->
             sa (cons t1 Γ) s2 t2 ->
             sa Γ (tall s1 s2) (tall t1 t2)
.
Derive Signature for sa.

Inductive sa_env : forall {n}, env O n -> env O n -> Prop :=
| sa_empty : sa_env (empty eq_refl) (empty eq_refl)
| sa_cons : forall {n} (Γ Δ : env O n) a b,
              sa Γ a b ->
              sa_env Γ Δ -> sa_env (cons a Γ) (cons b Δ)
.
Derive Signature for sa_env.

Lemma sa_refl : forall {n} (Γ : env O n) x, sa Γ x x.
Proof. depind x; constructor; auto. Qed.

Lemma sa_env_refl : forall {n} (Γ : env O n), sa_env Γ Γ.
Proof. depind Γ; subst; constructor; auto using sa_refl. Qed.

Inductive env_extend : forall {b c}, env O b -> env O c -> scope_le b c -> Prop :=
| env_extend_refl : forall {b} (Γ : env O b), env_extend Γ Γ (scope_le_n eq_refl)
| env_extend_cons : forall {b c} (Γ : env O b) (Δ : env O c) p a,
                      env_extend Γ Δ p -> env_extend (cons a Γ) (cons (lift_type_by p a) Δ) (scope_le_map p)
| env_extend_2 : forall {b c} (Γ : env O b) (Δ : env O c) p a,
                      env_extend Γ Δ p -> env_extend Γ (cons a Δ) (scope_le_S p)
.
Derive Signature for env_extend.

Lemma env_app_extend {b c} (Γ : env O b) (Δ : env b c) : env_extend Γ (env_app Γ Δ) (env_scope_le Δ).
Proof.
  depind Δ; subst; intros; autorewrite with env_app scope_le_app in *; simpl;
  constructor; auto.
Qed.

Lemma env_extend_lookup {b c} (Γ : env O b) (Δ : env O c) P :
  env_extend Γ Δ P -> forall x, lift_type_by P (lookup Γ x) = lookup Δ (lift_var_by P x).
Proof with autorewrite with lift_type_by lift_var_by map_var lookup scope_le_app; auto.
  intros A; depind A; intros x; depelim x...
  all:rewrite <- IHA...
Qed.

Lemma sa_weakening {b} (Γ : env O b) p q (A : sa Γ p q) :
  forall {c P} (Δ : env O c) (B : env_extend Γ Δ P),
    sa Δ (lift_type_by P p) (lift_type_by P q).
Proof.
  induction A; intros c P Δ B;
  autorewrite with lift_type_by in *;
  try (auto; constructor; auto; fail).
  - depelim c; [depelim B|].
    constructor; rewrite <- (env_extend_lookup _ _ _ B); auto.
  - constructor; auto.
    eapply IHA2. constructor. auto.
Qed.

Lemma sa_weakening_app {b} (Γ : env O b) p q (A : sa Γ p q) {c} (Δ : env b c) :
  sa (env_app Γ Δ) (lift_type_by (env_scope_le Δ) p) (lift_type_by (env_scope_le Δ) q).
Proof.
  intros; eapply sa_weakening.
  exact A.
  auto using env_app_extend.  
Qed.

Lemma sa_toname {n m} Γ (Δ : env (S n) m) x :
  x <> lift_var_by (env_scope_le Δ) FO ->
  forall p q, lookup (env_app (cons p Γ) Δ) x = lookup (env_app (cons q Γ) Δ) x.
Proof.
  depind Δ; subst; intros A p q;
  depelim x; simpl in *;
  autorewrite with env_app lookup lift_var_by in *; auto.
  - exfalso; auto.
  - specialize (IHΔ Γ x). forward IHΔ by intro; subst; auto.
    now rewrite (IHΔ p q).
Qed.

Lemma var_dec_eq : forall {n} (x y : var n), {x = y} + {x <> y}.
Proof.
  depind x; depelim y.
  - left; reflexivity.
  - right; intro H; depelim H.
  - right; intro H; depelim H.
  - destruct (IHx y); subst.
    + left; reflexivity.
    + right; intro H; depelim H. contradiction.
Qed.

Lemma sa_narrowing {s} q :
  (forall {s'} (P : scope_le s s') (Γ : env O s') p (A : sa Γ p (lift_type_by P q))
          s'' (Δ : env (S s') s'')
          a b (B : sa (env_app (cons (lift_type_by P q) Γ) Δ) a b),
      sa (env_app (cons p Γ) Δ) a b) /\
  (forall {s'} (A : scope_le s s') (Γ : env O s') p (B : sa Γ p (lift_type_by A q))
          r (C : sa Γ (lift_type_by A q) r),
      sa Γ p r).
Proof.
  induction q;
  match goal with
    | [ |- _ /\ ?Q ] => 
      assert (PLOP:Q);
        [ intros s' A Γ p B; depind B; subst; intros r C;
          autorewrite with lift_type_by lift_var_by in *; try noconf H; 
          try (constructor; auto; fail);
          try (constructor; eapply IHB; autorewrite with lift_type_by; auto; fail);
          try (depelim C; subst; constructor; destruct_pairs; try noconf H; eauto; fail);
          try (specialize (IHB _ _ _ IHq1 IHq2 A); destruct_pairs; try noconf H; constructor; eauto; fail); auto
        | split;
          [ intros s' P Γ p A; depind A; subst;
            intros s'' Δ a b B; destruct_pairs;
            remember (env_app (cons _ Γ) Δ) as PPP; depind B;
            try (subst; constructor; auto; autorewrite with core; auto; fail);
            clear B; constructor; specialize (IHB _ HeqPPP); subst *;
            try (noconf H; auto);
            match goal with
              | [ IHB : sa _ (lookup (env_app (cons ?a _) _) ?x) _
                  |- sa _ (lookup (env_app (cons ?b _) _) _) _ ] =>
                destruct (var_dec_eq x (lift_var_by (env_scope_le Δ) FO)) as [Heq|Hneq] ;
                  [ subst;
                    autorewrite with lookup lift_type_by lift_var_by in *;
                    try (noconf H; auto);
                    autorewrite with lookup lift_type_by lift_var_by scope_le_app in *;
                    try solve [auto; depelim IHB;
                               autorewrite with lookup lift_type_by lift_var_by scope_le_app in *;
                               auto; constructor; auto; fail];
                    try solve [(apply sa_var_trans in A || assert (A := sa_arr A1 A2) || assert (A := sa_all A1 A2));
                         match goal with
                           | [ A : sa _ ?p _ |- _ ] =>
                             (apply sa_weakening_app with (Δ0:=cons p (empty eq_refl)) in A;
                              apply sa_weakening_app with (Δ0:=Δ) in A;
                              autorewrite with lookup env_app lift_var_by lift_type_by in *; simpl in *;
                              eapply PLOP; [exact A | exact IHB])
                         end; fail]
                  | rewrite sa_toname with (p:=b) (q:=a); auto
                  ]
            end
          | assumption
          ]
        ]
  end.
  - clear IHB1 IHB2.
    depelim C; [constructor|]; destruct_pairs.
    constructor; eauto.
    simpl in H. simpl in H0.
    apply (H1 _ A Γ _ C1 _ (empty eq_refl) _ _) in B2; autorewrite with env_app in B2; eauto.
Qed.

Print Assumptions sa_narrowing.
(* Closed under the global context *)