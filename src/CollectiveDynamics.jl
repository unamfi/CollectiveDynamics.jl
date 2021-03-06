## =========================== ## ## =========================== ##
## 	   Package of functions of collective motion models			 ##
## 	   and its statistics                           			 ##
##	   Martin Zumaya Hernandez 						             ##
##     10 / 03 / 2017									         ##
## =========================== ## ## =========================== ##

module CollectiveDynamics

export InertialFlock, InertialNonLocFlock, InertialParameters, LocNonLocFlock, LocNonLocParameters, full_time_evolution_inertial_system, full_time_evolution_nonLocal_inertial_system, set_output_data_structure_inertial, set_output_data_structure_inertial_nonLocal, full_time_evolution_2D, full_time_evolution_2D_MOD, full_time_evolution_3D, full_time_evolution_3D_MOD, set_output_data_structure_lnl
##  LOCAL + NON_LOCAL INTERACTIONS MODEL
include("local_nonLocal.jl")

##  INTERIAL TURN FLOCK MODEL
include("turn_flock.jl")

module DataAnalysis

export make_dir_from_path, calc_rij_2D_vect, calc_rij_3D_vect, calc_vect_2D_cm, calc_vect_3D_cm, get_times
## DATA ANALYISIS UTILS FUNCTONS
include("utils_funcs.jl")

end

end
