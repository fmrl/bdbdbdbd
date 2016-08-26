// $legal:629:
//
// Copyright 2016 Michael Lowell Roberts & Microsoft Research
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//,$

module Flutterbye.Linearization
open FStar.Seq
open Flutterbye.Seq
open Flutterbye.Entropy

type transaction_t 'a = 'a -> 'a

type xnid_t (#a_t:Type) (todo:seq (transaction_t a_t)) =
   | XnId: as_nat:nat{as_nat < length todo} -> xnid_t todo

type pending_t (#a_t:Type) (todo:seq (transaction_t a_t)) =
   | Pending: id:xnid_t todo -> s:a_t -> pending_t todo

type step_t (#a_t:Type) (todo:seq (transaction_t a_t)) =
   | Next: id:xnid_t todo -> step_t todo
   | Studder: id:xnid_t todo -> step_t todo

type next_loop_p: 
   a_t:Type 
   -> xns:seq (transaction_t a_t)
   -> a:a_t
   -> pending:seq (pending_t xns)
   -> steps':seq (step_t xns)
=
   fun a_t xns a pending steps' ->
      length xns > 0
      /\ ((exists (x:nat{x < length steps'}).
            is_Next (index steps' x))
          \/ (exists (x:nat{x < length pending}).
                Pending.s (index pending x) = a))

val next_loop:
   xns:seq (transaction_t 'a)
   -> a:'a
   -> pending:seq (pending_t xns)
   -> steps:seq (step_t xns)
   -> Tot (steps':seq (step_t xns){next_loop_p xns a pending steps'})
      decreases (length pending)
let rec next_loop xns a pending steps =
   let i = 0 in
   let p = index pending i in
   let id = Pending.id p in
   let allow = (Pending.s p = a) in
   if allow then
      append (create (Step id) 1)
   else
      let steps' = append (create (Studder id) 1) in
      let retry = Pending id a in
      let pending' = remove pending i in
      next_loop xns a pending' steps'


(*type linearized_p (#a_t:Type) (#b_t:Type) (todo:seq (transaction_t a_t)) (s_0:a_t) (l:seq (step_t todo)) =
   length todo = 0
   \/ // every transaction has a corresponding `Step` operation in
      // the linearization sequence.
      forall (x:xnid_t todo).
         (exists (y:nat{y < length l}).
            let op = index l y in
            is_Step op && Step.id op = x)

val linearize:
   todo:seq (transaction_t 'a)
   -> s_0:'a
   -> e:entropy_t 'b
   -> Tot (l:seq (step_t 'a)){linearized_p todo s_0 l})
let linearize todo s_0 =
   let p = 
      map
         (fun i x ->
            Pending i s_0)
         todo
   in
   linearize_loop todo p createEmpty
*)