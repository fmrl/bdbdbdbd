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

module Flutterbye.Seq.Remove
open FStar.Seq

private type removed_p (#a_t:Type) (s:seq a_t{length s > 0}) (i:nat{i < length s}) (a:a_t) (s':seq a_t) =
   length s' = length s - 1 /\
   (forall (x:nat).
      x < i ==> index s' x = index s x) /\
   (forall (x:nat).
      i < x && x < length s' ==>
         index s' x = index s (x + 1))(* /\
   (i = 0 ==> equal s' (slice s 1 (length s - 1))) /\
   (i = length s ==> equal s' (slice s 0 (length s - 2)))

val remove:
   s:seq 'a{length s > 0}
   -> i:nat{i < length s}
   -> a:'a
   -> Tot (s':seq 'a{removed_p s i a s'})
let remove s i a =
   let l = slice s 0 i in
   let r = slice s (i + 1) (length s) in
   append l r