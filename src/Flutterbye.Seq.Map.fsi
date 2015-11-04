(*--build-config
   options:--admit_fsi FStar.Seq;
   other-files:seq.fsi
--*)

// $legal:614:
//
// Copyright 2015 Michael Lowell Roberts
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
// ,$

module Flutterbye.Seq.Map
   open FStar.Seq

   // map seq 'a to seq 'b given a function that maps 'a to 'b.
   val map: ('a -> Tot 'b) -> s: seq 'a -> Tot (seq 'b)

   val lemma__preserves_length:
      f: ('a -> Tot 'b)
      -> s: seq 'a
      -> Lemma
         (requires (True))
         (ensures (length (map f s) = length s))
         [SMTPat (length (map f s))]

   val lemma__mapping_of_elements:
      f: ('a -> Tot 'b)
      -> s: seq 'a
      -> i: nat{i < length s}
      -> Lemma
         (requires (True))
         (ensures (index (map f s) i = f (index s i)))
         [SMTPat (index (map f s) i)]
