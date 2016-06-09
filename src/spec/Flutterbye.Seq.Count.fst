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

module Flutterbye.Seq.Count
open FStar.Seq
open Flutterbye.Seq.Filter

val count:
   ('a -> Tot bool)
      // predicate; if false, the element is discarded from the count.
   -> s:seq 'a // input sequence
   -> Tot (n:nat{n <= length s})
let count p s =
   Flutterbye.Seq.Filter.lemma__length p s;
   length (filter p s)