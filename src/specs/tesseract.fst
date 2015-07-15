(*--build-config
   other-files:ext.fst set.fst map.fst seq.fst effects.fst region.fst
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

module Tesseract.Specs.Tesseract

   val __tesseract_effect_log_recursion:
      log: Effects._log_g 'state 'step
      -> Lemma
         (ensures True)
         (decreases (Seq.length log))
   let rec __tesseract_effect_log_recursion log =
      let length = Seq.length log in
         if 0 = length then
            ()
         else
            __tesseract_effect_log_recursion (Seq.slice log 0 (length - 1))

   val __effect_log_safety: Effects._log_g 'state 'step -> Tot bool
   let rec __effect_log_safety _log =
      __tesseract_effect_log_recursion log;
      (0 = Seq.length _log)
      || (let f
            = (fun (accum: option nat) (index: Seq.Index _log)
               -> match accum with
                     | None ->
                        // an unsafe tesseract continues to be unsafe.
                        None
                     | Some count ->
                        // examine the next effect in the sequence.
                        (match Seq.nth _log index with
                           | Effects.Spawn _ _ ->
                              Some (count + 1)
                           | Effects.Step region_id _ ->
                              // a step effect must be associated with a region id that is smaller than the number of spawn effects encountered so far.
                              if region_id < count then
                                 accum
                              else
                                 None))
            in (is_Some (Seq.foldl _log f (Some 0)))
         && (__effect_log_safety (Seq.slice _log 0 (Seq.length _log - 1))))

   type _tesseract_g
      (state_t: Type)
      (step_kind_t: Type)
      = { effect_log: Effects._log_g state_t step_kind_t; }

   type TesseractSafety:
      #state_t: Type
      -> #step_kind_t: Type
      -> _tesseract_g state_t step_kind_t
      -> Type
   = fun
      (state_t: Type)
      (step_kind_t: Type)
      (_tess: _tesseract_g state_t step_kind_t)
      -> b2t (__effect_log_safety _tess.effect_log)

   type tesseract_g
      (state_t: Type)
      (step_kind_t: Type)
      = _tess:
         _tesseract_g
            state_t
            step_kind_t{TesseractSafety _tess}

   val init:
      #state_t: Type
      -> #step_kind_t: Type
      -> Tot (tesseract_g state_t step_kind_t)
   let init
      (state_t: Type)
      (step_kind_t: Type)
      = { effect_log = Seq.empty; }

   val regions:
      #state_t: Type
      -> #step_kind_t: Type
      -> tess: tesseract_g state_t step_kind_t
      -> Tot (Effects.region_id_t)
   let regions
      (state_t: Type)
      (step_kind_t: Type)
      tess
      = Seq.count Effects.is_Spawn tess.effect_log

   val is_region:
      #state_t: Type
      -> #step_kind_t: Type
      -> tesseract_g state_t step_kind_t
      -> Effects.region_id_t
      -> Tot bool
   let is_region
      (state_t: Type)
      (step_kind_t: Type)
      tess
      region_id
      = region_id < regions tess

   val find_spawn:
      #state_t: Type
      -> #step_kind_t: Type
      -> tess: tesseract_g state_t step_kind_t
      -> region_id: Effects.region_id_t{is_region tess region_id}
      -> Tot (Seq.Index tess.effect_log)
   let find_spawn
      (state_t: Type)
      (step_kind_t: Type)
      tess
      region_id
      =  let log = tess.effect_log in
         let f
            = fun (accum: (either nat (Seq.Index log))) (index: Seq.Index log)
               -> (match accum with
                     | Inl count ->
                        // examine the next effect in the sequence.
                        (match Seq.nth log index with
                           | Effects.Spawn _ _ ->
                              if count = region_id then
                                 Inr index
                              else
                                 Inl (count + 1)
                           | _ ->
                              accum)
                     | _ ->
                        accum) in
         match Seq.foldl log f (Inl 0) with
            Inr index ->
               index

   val lookup:
      #state_t: Type
      -> #step_kind_t: Type
      -> tess: tesseract_g state_t step_kind_t
      -> region_id: Effects.region_id_t{is_region tess region_id}
      -> Tot (Region.region_g state_t step_kind_t)
   let lookup
      (state_t: Type)
      (step_kind_t: Type)
      tess
      region_id
      =  let start = find_spawn tess region_id in
         let head = Seq.nth tess.effect_log start in
         // todo: what do i need to write that would make it unnecessary to
         // slice the effect log before filtering it?
         let tail = Seq.slice tess.effect_log start (Seq.length tess.effect_log) in
         let pred =
            (fun item ->
               Effects.is_Step item && region_id = Effects.Step.region_id item) in
         let log = Seq.prepend head (Seq.filter pred tail) in
         Region.make region_id log

   val spawn:
      #state_t: Type
      -> #step_kind_t: Type
      -> tess: tesseract_g state_t step_kind_t
      -> region_id: Effects.region_id_t{not (is_region tess region_id)}
      -> state_t
      -> Effects.step_g state_t step_kind_t
      -> Tot (tesseract_g state_t step_kind_t)
   let spawn
      (state_t: Type)
      (step_kind_t: Type)
      tess
      region_id
      state0
      step
      = { effect_log = Seq.append tess.effect_log (Effects.Spawn state0 step); }

   val step:
      #state_t: Type
      -> #step_kind_t: Type
      -> tess: tesseract_g state_t step_kind_t
      -> region_id: Effects.region_id_t{is_region tess region_id}
      -> step_kind_t
      -> Tot (tesseract_g state_t step_kind_t)
   let step
      (state_t: Type)
      (step_kind_t: Type)
      tess
      region_id
      step_kind
      = { effect_log = Seq.append tess.effect_log (Effects.Step region_id step_kind); }

// $vim-fst:32: vim:set sts=3 sw=3 et ft=fstar:,$
