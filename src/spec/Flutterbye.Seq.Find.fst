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

module Flutterbye.Seq.Find
open FStar.Seq
open Flutterbye.Option

private val find__loop:
   f:('a -> Tot bool)
   -> s:seq 'a
   -> i:nat{i <= length s}
   -> c:(option nat)
   -> Tot (option nat)
      (decreases (length s - i))
let rec find__loop f s i c =
   if i < length s then
      let c' =
         if is_None c && (f (index s i)) then
            Some i
         else
            c in
      find__loop f s (i + 1) c'
   else
      c

type found_t (#a:Type) (f:(a -> Tot bool)) (s:seq a) (i:option nat) =
   (is_None i ==>
      (forall (j:nat).
         j < length s ==> not (f (index s j)))) /\
   (is_Some i ==>
      b2t (get i < length s && f (index s (get i))))

private val lemma__find__loop:
   f:('a -> Tot bool)
   -> s:seq 'a
   -> i:nat{i <= length s}
   -> c:(option nat)
   -> Lemma
      (requires
         ((is_None c ==>
            (forall (j:nat).
               (j < i) ==> (not (f (index s j)))))
         /\ (is_Some c ==>
               ((get c) < length s
               && (f (index s (get c)))))))
      (ensures
         ((is_None (find__loop f s i c) ==>
            (forall (j:nat).
               (j < length s) ==> (not (f (index s j)))))
         /\ (is_Some (find__loop f s i c) ==>
               ((get (find__loop f s i c)) < length s
               && (f (index s (get (find__loop f s i c))))))))
      (decreases (length s - i))
let rec lemma__find__loop f s i c =
   if i < length s then
      let c' =
         if is_None c && (f (index s i)) then
            Some i
         else
            c in
      lemma__find__loop f s (i + 1) c'
   else
      ()

val find: 
   f:('a -> Tot bool) -> 
   s:seq 'a -> 
   Tot (i:option nat{found_t f s i})
let find f s =
   lemma__find__loop f s 0 None;
   find__loop f s 0 None
