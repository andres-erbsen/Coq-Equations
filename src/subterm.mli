(**********************************************************************)
(* Equations                                                          *)
(* Copyright (c) 2009-2021 Matthieu Sozeau <matthieu.sozeau@inria.fr> *)
(**********************************************************************)
(* This file is distributed under the terms of the                    *)
(* GNU Lesser General Public License Version 2.1                      *)
(**********************************************************************)

val derive_subterm :
  pm:Declare.OblState.t ->
  Environ.env -> Evd.evar_map -> poly:bool -> Names.inductive * EConstr.EInstance.t ->
  Declare.OblState.t

val derive_below : Environ.env -> Evd.evar_map -> poly:bool -> Names.inductive * EConstr.EInstance.t -> unit
