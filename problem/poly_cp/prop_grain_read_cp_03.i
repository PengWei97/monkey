[Mesh]
  type = GeneratedMesh
  dim = 2
  elem_type = QUAD4
  displacements = 'disp_x disp_y'
  nx = 100
  ny = 100
  xmax = 0.21
  ymax = 0.21
[]

[Variables]
  [./disp_x]
    block = 0
  [../]
  [./disp_y]
    block = 0
  [../]
[]

[GlobalParams]
  volumetric_locking_correction=true
[]

[AuxVariables]
  [./stress_yy]
    order = CONSTANT
    family = MONOMIAL
    block = 0
  [../]
  [./e_yy]
    order = CONSTANT
    family = MONOMIAL
    block = 0
  [../]
  [./euler1]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./euler2]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./euler3]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[Functions]
  [./tdisp]
    type = ParsedFunction
    value = 2e-4*t
  [../]
[]

[UserObjects]
  [./prop_read]
    type = ElementPropertyReadFile
    # need read
    prop_file_name = 'input_file.txt' # euler angle
    # Enter file data as prop#1, prop#2, .., prop#nprop
    nprop = 3
    read_type = grain
    ngrain = 200
    # rand_seed = 25346
    rve_type = periodic
    # Periodic or non-periodic grain distribution: Default is non-periodic
  [../]
[]

[AuxKernels]
  [./stress_yy]
    type = RankTwoAux
    variable = stress_yy
    rank_two_tensor = stress
    index_j = 1
    index_i = 1
    execute_on = 'initial timestep_end'
    block = 0
  [../]
  [./e_yy]
    type = RankTwoAux
    variable = e_yy
    rank_two_tensor = lage
    index_j = 1
    index_i = 1
    execute_on = timestep_end
    block = 0
  [../]
  [./euler1]
    type = MaterialRealVectorValueAux
    variable = euler1
    property = Euler_angles
    component = 0
    execute_on = timestep_end
  [../]
  [./euler2]
    type = MaterialRealVectorValueAux
    variable = euler2
    property = Euler_angles
    component = 1
    execute_on = timestep_end
  [../]
  [./euler3]
    type = MaterialRealVectorValueAux
    variable = euler3
    property = Euler_angles
    component = 2
    execute_on = timestep_end
  [../]
[]

[BCs]
  [./fix_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'left'
    value = 0
  [../]
  [./fix_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'bottom'
    value = 0
  [../]
  [./tdisp]
    type = FunctionDirichletBC
    variable = disp_y
    boundary = top
    function = tdisp
  [../]
[]

[UserObjects]
  [./slip_rate_gss]
    type = CrystalPlasticitySlipRateGSS
    variable_size = 12
    slip_sys_file_name = input_slip_sys.txt # slip system
    num_slip_sys_flowrate_props = 2
    flowprops = '1 4 0.001 0.1 5 8 0.001 0.1 9 12 0.001 0.1'
    uo_state_var_name = state_var_gss
  [../]
  [./slip_resistance_gss]
    type = CrystalPlasticitySlipResistanceGSS
    variable_size = 12
    uo_state_var_name = state_var_gss
  [../]
  [./state_var_gss]
    type = CrystalPlasticityStateVariable
    variable_size = 12
    groups = '0 4 8 12'
    group_values = '60.8 60.8 60.8'
    uo_state_var_evol_rate_comp_name = state_var_evol_rate_comp_gss
    scale_factor = 1.0
  [../]
  [./state_var_evol_rate_comp_gss]
    type = CrystalPlasticityStateVarRateComponentGSS
    variable_size = 12
    hprops = '1.0 541.5 109.8 2.5'
    uo_slip_rate_name = slip_rate_gss
    uo_state_var_name = state_var_gss
  [../]
[]

[Materials]
  [./crysp]
    type = FiniteStrainUObasedCP
    stol = 1e-2
    tan_mod_type = exact
    uo_slip_rates = 'slip_rate_gss'
    uo_slip_resistances = 'slip_resistance_gss'
    uo_state_vars = 'state_var_gss'
    uo_state_var_evol_rate_comps = 'state_var_evol_rate_comp_gss'
    maximum_substep_iteration = 5 # add for an advice of jiangwen84
  [../]
  [./strain]
    type = ComputeFiniteStrain
    displacements = 'disp_x disp_y'
  [../]
  [./elasticity_tensor]
    type = ComputeElasticityTensorCP
    C_ijkl = '1.684e5 1.214e5 1.214e5 1.684e5 1.214e5 1.684e5 0.754e5 0.754e5 0.754e5'
    fill_method = symmetric9
    read_prop_user_object = prop_read
  [../]
[]

[Postprocessors]
  [./stress_yy]
    type = ElementAverageValue
    variable = stress_yy
    block = 'ANY_BLOCK_ID 0'
  [../]
  [./e_yy]
    type = ElementAverageValue
    variable = e_yy
    block = 'ANY_BLOCK_ID 0'
  [../]
[]

[Preconditioning]
  [./smp]
    type = SMP
    full = true
  [../]
[]

[Executioner]
  type = Transient
  # dt = 0.05

  #Preconditioned JFNK (default)
  solve_type = 'PJFNK'

  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = 'lu boomerang'
  nl_abs_tol = 1e-10
  nl_rel_step_tol = 1e-10
  dtmax = 10.0
  nl_rel_tol = 1e-10
  end_time = 20
  dtmin = 0.001
  # num_steps = 10
  nl_abs_step_tol = 1e-10

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.05 # Initial time step.  In this simulation it changes.
    optimal_iterations = 6 # Time step will adapt to maintain this number of nonlinear iterations
  [../]
[]

[Outputs]
  file_base = prop_grain_read_out_xiu03 # add -pc_type add time 20,pgraph
  exodus = true
  csv = true
  [pgraph]
    type = PerfGraphOutput
    execute_on = 'initial final'  # Default is "final"
    level = 2                     # Default is 1
    heaviest_branch = true        # Default is false
    heaviest_sections = 7         # Default is 0
  []
[]

[Kernels]
  [./TensorMechanics]
    displacements = 'disp_x disp_y'
    use_displaced_mesh = true
  [../]
[]
