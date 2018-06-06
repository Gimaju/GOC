
function run_hierarchy(problem::Problem, relax_ctx::RelaxationContext, logpath; indentedprint=false,
                                                                                max_cliques::SortedDict{String, SortedSet{Variable}}=SortedDict{String, SortedSet{Variable}}(),
                                                                                save_pbs=false)

    open(joinpath(logpath, "pb_opt.log"), "w") do fout
        print(fout, problem)
    end

    ########################################
    # Construction du sparsity pattern, extension chordale, cliques maximales.
    if max_cliques == SortedDict{String, SortedSet{Variable}}()
        max_cliques = get_maxcliques(relax_ctx, problem)
    end

    ########################################
    # Compute moment matrices parameters: order et variables
    momentmat_param, localizingmat_param = build_sparsity(relax_ctx, problem, max_cliques)

    ########################################
    # Compute moment and localization matrices
    mmtrel_pb = MomentRelaxation{Float64}(relax_ctx, problem, momentmat_param, localizingmat_param, max_cliques)

    if save_pbs
        open(joinpath(logpath, "mmt_pb.log"), "w") do fout
            print(fout, mmtrel_pb)
        end
    end

    ########################################
    # Convert to a primal SDP problem
    sdpinstance = build_SDPInstance(relax_ctx, mmtrel_pb)

    export_SDP(sdpinstance, logpath, indentedprint=indentedprint)

    sdp = build_mosekpb(logpath)

    primal = SortedDict{Tuple{String,String,String}, Float64}()
    dual = SortedDict{Tuple{String, String, String}, Float64}()

    primobj, dualobj = solve_mosek(sdp::SDP_Problem, primal, dual; logname = joinpath(logpath, "Mosek_run.log"))

    info("Writing results to $logpath")
    params_file = joinpath(logpath, "maxcliques_relaxctx.txt")
    isfile(params_file) && rm(params_file)
    open(params_file, "w") do fcliques
        println(fcliques, "# max_cliques are:")
        println(fcliques, max_cliques)
        println(fcliques, "# relaxation_ctx is:")
        println(fcliques, relax_ctx)
    end

    return primobj, dualobj
end

function build_relaxation(problem::Problem, relax_ctx::RelaxationContext; max_cliques::SortedDict{String, SortedSet{Variable}} = SortedDict{String, SortedSet{Variable}}())

    ########################################
    # Construction du sparsity pattern, extension chordale, cliques maximales.
    if max_cliques == Dict{String, SortedSet{Variable}}()
        max_cliques = get_maxcliques(relax_ctx, problem)
    end

    ########################################
    # Compute moment matrices parameters: order et variables
    momentmat_param, localizingmat_param = build_sparsity(relax_ctx, problem, max_cliques)

    ########################################
    # Compute moment and localization matrices
    mmtrel_pb = MomentRelaxation{Float64}(relax_ctx, problem, momentmat_param, localizingmat_param, max_cliques)

    ########################################
    # Convert to a primal SDP problem
    sdpinstance = build_SDPInstance(relax_ctx, mmtrel_pb)

    return sdpinstance

end


"""
    sdp = build_mosekpb(logpath)

    Build the sdp problem described at `logpath` into the generic structure interfaced with SDP solvers (Mosek for now).
"""
function build_mosekpb(logpath::String)
    sdp_instance = read_SDPInstance(logpath)

    sdp = SDP_Problem()

    set_constraints!(sdp, sdp_instance)
    set_vartypes!(sdp, sdp_instance)
    set_blocks!(sdp, sdp_instance)
    set_linvars!(sdp, sdp_instance)

    set_matrices!(sdp, sdp_instance)
    set_linear!(sdp, sdp_instance)
    set_const!(sdp, sdp_instance)
    return sdp
end


function build_mosekpb(SOS_pb::SDPInstance, logpath::String; indentedprint=false)
    export_SDP(SOS_pb, logpath, indentedprint=indentedprint)

    sdp = build_mosekpb(logpath)

    sdp_instance = read_SDPInstance(logpath)

    sdp = SDP_Problem()

    set_constraints!(sdp, sdp_instance)
    set_vartypes!(sdp, sdp_instance)
    set_blocks!(sdp, sdp_instance)
    set_linvars!(sdp, sdp_instance)

    set_matrices!(sdp, sdp_instance)
    set_linear!(sdp, sdp_instance)
    set_const!(sdp, sdp_instance)
    return sdp
end

