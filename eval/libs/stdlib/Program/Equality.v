From Hammer Require Import Hammer.











Require Export JMeq.

Require Import Coq.Program.Tactics.

Ltac is_ground_goal :=
match goal with
|- ?T => is_ground T
end.



Hint Extern 10 => is_ground_goal ; progress exfalso : exfalso.



Definition block {A : Type} (a : A) := a.

Ltac block_goal := match goal with [ |- ?T ] => change (block T) end.
Ltac unblock_goal := unfold block in *.



Notation " x ~= y " := (@JMeq _ x _ y) (at level 70, no associativity).



Ltac on_JMeq tac :=
match goal with
| [ H : @JMeq ?x ?X ?y ?Y |- _ ] => tac H
end.



Ltac simpl_one_JMeq :=
on_JMeq ltac:(fun H => apply JMeq_eq in H).



Ltac simpl_JMeq := repeat simpl_one_JMeq.



Ltac simpl_one_dep_JMeq :=
on_JMeq
ltac:(fun H => let H' := fresh "H" in
assert (H' := JMeq_eq H)).

Require Import Eqdep.



Ltac simpl_existT :=
match goal with
[ H : existT _ ?x _ = existT _ ?x _ |- _ ] =>
let Hi := fresh H in assert(Hi:=inj_pairT2 _ _ _ _ _ H) ; clear H
end.

Ltac simpl_existTs := repeat simpl_existT.



Ltac elim_eq_rect :=
match goal with
| [ |- ?t ] =>
match t with
| context [ @eq_rect _ _ _ _ _ ?p ] =>
let P := fresh "P" in
set (P := p); simpl in P ;
((case P ; clear P) || (clearbody P; rewrite (UIP_refl _ _ P); clear P))
| context [ @eq_rect _ _ _ _ _ ?p _ ] =>
let P := fresh "P" in
set (P := p); simpl in P ;
((case P ; clear P) || (clearbody P; rewrite (UIP_refl _ _ P); clear P))
end
end.



Ltac simpl_uip :=
match goal with
[ H : ?X = ?X |- _ ] => rewrite (UIP_refl _ _ H) in *; clear H
end.



Ltac simpl_eq := simpl ; unfold eq_rec_r, eq_rec ; repeat (elim_eq_rect ; simpl) ; repeat (simpl_uip ; simpl).



Ltac abstract_eq_hyp H' p :=
let ty := type of p in
let tyred := eval simpl in ty in
match tyred with
?X = ?Y =>
match goal with
| [ H : X = Y |- _ ] => fail 1
| _ => set (H':=p) ; try (change p with H') ; clearbody H' ; simpl in H'
end
end.



Ltac on_coerce_proof tac T :=
match T with
| context [ eq_rect _ _ _ _ ?p ] => tac p
end.

Ltac on_coerce_proof_gl tac :=
match goal with
[ |- ?T ] => on_coerce_proof tac T
end.



Ltac abstract_eq_proof := on_coerce_proof_gl ltac:(fun p => let H := fresh "eqH" in abstract_eq_hyp H p).

Ltac abstract_eq_proofs := repeat abstract_eq_proof.



Ltac pi_eq_proof_hyp p :=
let ty := type of p in
let tyred := eval simpl in ty in
match tyred with
?X = ?Y =>
match goal with
| [ H : X = Y |- _ ] =>
match p with
| H => fail 2
| _ => rewrite (UIP _ X Y p H)
end
| _ => fail " No hypothesis with same type "
end
end.



Ltac pi_eq_proof := on_coerce_proof_gl pi_eq_proof_hyp.

Ltac pi_eq_proofs := repeat pi_eq_proof.



Ltac clear_eq_proofs :=
abstract_eq_proofs ; pi_eq_proofs.

Hint Rewrite <- eq_rect_eq : refl_id.



Lemma JMeq_eq_refl {A} (x : A) : JMeq_eq (@JMeq_refl _ x) = eq_refl.
Proof. try hammer_hook "Equality" "Equality.JMeq_eq_refl".   apply UIP. Qed.

Lemma UIP_refl_refl A (x : A) :
Eqdep.EqdepTheory.UIP_refl A x eq_refl = eq_refl.
Proof. try hammer_hook "Equality" "Equality.UIP_refl_refl".   apply UIP_refl. Qed.

Lemma inj_pairT2_refl A (x : A) (P : A -> Type) (p : P x) :
Eqdep.EqdepTheory.inj_pairT2 A P x p p eq_refl = eq_refl.
Proof. try hammer_hook "Equality" "Equality.inj_pairT2_refl".   apply UIP_refl. Qed.

Hint Rewrite @JMeq_eq_refl @UIP_refl_refl @inj_pairT2_refl : refl_id.

Ltac rewrite_refl_id := autorewrite with refl_id.



Ltac clear_eq_ctx :=
rewrite_refl_id ; clear_eq_proofs.



Ltac simpl_eqs :=
repeat (elim_eq_rect ; simpl ; clear_eq_ctx).



Ltac clear_refl_eq :=
match goal with [ H : ?X = ?X |- _ ] => clear H end.
Ltac clear_refl_eqs := repeat clear_refl_eq.



Ltac clear_eq :=
match goal with [ H : _ = _ |- _ ] => clear H end.
Ltac clear_eqs := repeat clear_eq.



Ltac simplify_eqs :=
simpl ; simpl_eqs ; clear_eq_ctx ; clear_refl_eqs ;
try subst ; simpl ; repeat simpl_uip ; rewrite_refl_id.



Ltac simplify_IH_hyps := repeat
match goal with
| [ hyp : context [ block _ ] |- _ ] =>
specialize_eqs hyp
end.



Ltac subst_left_no_fail :=
repeat (match goal with
[ H : ?X = ?Y |- _ ] => subst X
end).

Ltac subst_right_no_fail :=
repeat (match goal with
[ H : ?X = ?Y |- _ ] => subst Y
end).

Ltac inject_left H :=
progress (inversion H ; subst_left_no_fail ; clear_dups) ; clear H.

Ltac inject_right H :=
progress (inversion H ; subst_right_no_fail ; clear_dups) ; clear H.

Ltac autoinjections_left := repeat autoinjection ltac:(inject_left).
Ltac autoinjections_right := repeat autoinjection ltac:(inject_right).

Ltac simpl_depind := subst_no_fail ; autoinjections ; try discriminates ;
simpl_JMeq ; simpl_existTs ; simplify_IH_hyps.

Ltac simpl_depind_l := subst_left_no_fail ; autoinjections_left ; try discriminates ;
simpl_JMeq ; simpl_existTs ; simplify_IH_hyps.

Ltac simpl_depind_r := subst_right_no_fail ; autoinjections_right ; try discriminates ;
simpl_JMeq ; simpl_existTs ; simplify_IH_hyps.

Ltac blocked t := block_goal ; t ; unblock_goal.



Class DependentEliminationPackage (A : Type) :=
{ elim_type : Type ; elim : elim_type }.



Ltac elim_tac tac p :=
let ty := type of p in
let eliminator := eval simpl in (@elim (_ : DependentEliminationPackage ty)) in
tac p eliminator.



Ltac elim_case p := elim_tac ltac:(fun p el => destruct p using el) p.
Ltac elim_ind p := elim_tac ltac:(fun p el => induction p using el) p.



Lemma solution_left A (B : A -> Type) (t : A) :
B t -> (forall x, x = t -> B x).
Proof. try hammer_hook "Equality" "Equality.solution_left".   intros; subst; assumption. Defined.

Lemma solution_right A (B : A -> Type) (t : A) :
B t -> (forall x, t = x -> B x).
Proof. try hammer_hook "Equality" "Equality.solution_right".   intros; subst; assumption. Defined.

Lemma deletion A B (t : A) : B -> (t = t -> B).
Proof. try hammer_hook "Equality" "Equality.deletion".   intros; assumption. Defined.

Lemma simplification_heq A B (x y : A) :
(x = y -> B) -> (JMeq x y -> B).
Proof. try hammer_hook "Equality" "Equality.simplification_heq".   intros H J; apply H; apply (JMeq_eq J). Defined.

Definition conditional_eq {A} (x y : A) := eq x y.

Lemma simplification_existT2 A (P : A -> Type) B (p : A) (x y : P p) :
(x = y -> B) -> (conditional_eq (existT P p x) (existT P p y) -> B).
Proof. try hammer_hook "Equality" "Equality.simplification_existT2".   intros H E. apply H. apply inj_pair2. assumption. Defined.

Lemma simplification_existT1 A (P : A -> Type) B (p q : A) (x : P p) (y : P q) :
(p = q -> conditional_eq (existT P p x) (existT P q y) -> B) -> (existT P p x = existT P q y -> B).
Proof. try hammer_hook "Equality" "Equality.simplification_existT1".   injection 2. auto. Defined.

Lemma simplification_K A (x : A) (B : x = x -> Type) :
B eq_refl -> (forall p : x = x, B p).
Proof. try hammer_hook "Equality" "Equality.simplification_K".   intros. rewrite (UIP_refl A). assumption. Defined.



Hint Unfold solution_left solution_right deletion simplification_heq
simplification_existT1 simplification_existT2 simplification_K
eq_rect_r eq_rec eq_ind : dep_elim.



Ltac simplify_one_dep_elim_term c :=
match c with
| @JMeq _ _ _ _ -> _ => refine (simplification_heq _ _ _ _ _)
| ?t = ?t -> _ => intros _ || refine (simplification_K _ t _ _)
| eq (existT _ _ _) (existT _ _ _) -> _ =>
refine (simplification_existT1 _ _ _ _ _ _ _ _)
| conditional_eq (existT _ _ _) (existT _ _ _) -> _ =>
refine (simplification_existT2 _ _ _ _ _ _ _) ||
(unfold conditional_eq; intro)
| ?x = ?y -> _ =>
(unfold x) || (unfold y) ||
(let hyp := fresh in intros hyp ;
move hyp before x ; revert_until hyp ; generalize dependent x ;
refine (solution_left _ _ _ _)) ||
(let hyp := fresh in intros hyp ;
move hyp before y ; revert_until hyp ; generalize dependent y ;
refine (solution_right _ _ _ _))
| ?f ?x = ?g ?y -> _ => let H := fresh in progress (intros H ; simple injection H; clear H)
| ?t = ?u -> _ => let hyp := fresh in
intros hyp ; exfalso ; discriminate
| ?x = ?y -> _ => let hyp := fresh in
intros hyp ; (try (clear hyp ;  fail 1)) ;
case hyp ; clear hyp
| block ?T => fail 1
| forall x, _ => intro x || (let H := fresh x in rename x into H ; intro x)
| _ => intro
end.

Ltac simplify_one_dep_elim :=
match goal with
| [ |- ?gl ] => simplify_one_dep_elim_term gl
end.



Ltac simplify_dep_elim := repeat simplify_one_dep_elim.



Ltac destruct_last :=
on_last_hyp ltac:(fun id => simpl in id ; generalize_eqs id ; destruct id).

Ltac introduce p := first [
match p with _ =>
generalize dependent p ; intros p
end
| intros until p | intros until 1 | intros ].

Ltac do_case p := introduce p ; (destruct p || elim_case p || (case p ; clear p)).
Ltac do_ind p := introduce p ; (induction p || elim_ind p).





Ltac is_introduced H :=
match goal with
| [ H' : _ |- _ ] => match H' with H => idtac end
end.

Tactic Notation "intro_block" hyp(H) :=
(is_introduced H ; block_goal ; revert_until H ; block_goal) ||
(let H' := fresh H in intros until H' ; block_goal) || (intros ; block_goal).

Tactic Notation "intro_block_id" ident(H) :=
(is_introduced H ; block_goal ; revert_until H; block_goal) ||
(let H' := fresh H in intros until H' ; block_goal) || (intros ; block_goal).

Ltac unblock_dep_elim :=
match goal with
| |- block ?T =>
match T with context [ block _ ] =>
change T ; intros ; unblock_goal
end
| _ => unblock_goal
end.

Ltac simpl_dep_elim := simplify_dep_elim ; simplify_IH_hyps ; unblock_dep_elim.

Ltac do_intros H :=
(try intros until H) ; (intro_block_id H || intro_block H).

Ltac do_depelim_nosimpl tac H := do_intros H ; generalize_eqs H ; tac H.

Ltac do_depelim tac H := do_depelim_nosimpl tac H ; simpl_dep_elim.

Ltac do_depind tac H :=
(try intros until H) ; intro_block H ;
generalize_eqs_vars H ; tac H ; simpl_dep_elim.



Ltac depelim id := do_depelim ltac:(fun hyp => do_case hyp) id.



Ltac depelim_nosimpl id := do_depelim_nosimpl ltac:(fun hyp => do_case hyp) id.



Ltac depind id := do_depind ltac:(fun hyp => do_ind hyp) id.



Ltac do_depelim' rev tac H :=
(try intros until H) ; block_goal ;
(try revert_until H ; block_goal) ;
generalize_eqs H ; rev H ; tac H ; simpl_dep_elim.



Tactic Notation "dependent" "destruction" ident(H) :=
do_depelim' ltac:(fun hyp => idtac) ltac:(fun hyp => do_case hyp) H.

Tactic Notation "dependent" "destruction" ident(H) "using" constr(c) :=
do_depelim' ltac:(fun hyp => idtac) ltac:(fun hyp => destruct hyp using c) H.



Tactic Notation "dependent" "destruction" ident(H) "generalizing" ne_hyp_list(l) :=
do_depelim' ltac:(fun hyp => revert l) ltac:(fun hyp => do_case hyp) H.

Tactic Notation "dependent" "destruction" ident(H) "generalizing" ne_hyp_list(l) "using" constr(c) :=
do_depelim' ltac:(fun hyp => revert l) ltac:(fun hyp => destruct hyp using c) H.



Tactic Notation "dependent" "induction" ident(H) :=
do_depind ltac:(fun hyp => do_ind hyp) H.

Tactic Notation "dependent" "induction" ident(H) "using" constr(c) :=
do_depind ltac:(fun hyp => induction hyp using c) H.



Tactic Notation "dependent" "induction" ident(H) "generalizing" ne_hyp_list(l) :=
do_depelim' ltac:(fun hyp => revert l) ltac:(fun hyp => do_ind hyp) H.

Tactic Notation "dependent" "induction" ident(H) "generalizing" ne_hyp_list(l) "using" constr(c) :=
do_depelim' ltac:(fun hyp => revert l) ltac:(fun hyp => induction hyp using c) H.

Tactic Notation "dependent" "induction" ident(H) "in" ne_hyp_list(l) :=
do_depelim' ltac:(fun hyp => idtac) ltac:(fun hyp => induction hyp in l) H.

Tactic Notation "dependent" "induction" ident(H) "in" ne_hyp_list(l) "using" constr(c) :=
do_depelim' ltac:(fun hyp => idtac) ltac:(fun hyp => induction hyp in l using c) H.
