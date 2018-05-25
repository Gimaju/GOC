function build_SDPInstance(relaxctx::RelaxationContext, mmtrelax_pb::MomentRelaxationPb)
    sdpblocks = SDPBlocks()
    sdplin = SDPLin()
    sdplinsym = SDPLinSym()
    sdpcst = SDPCst()
    block_to_vartype = SortedDict{String, Symbol}()

    ## Build blocks dict
    for ((cstrname, cliquename), mmt) in mmtrelax_pb.constraints
        block_name = get_blockname(cstrname, cliquename, mmtrelax_pb)
        block_to_vartype[block_name] = mmt.matrixkind

        for ((γ, δ), poly) in mmt.mm
            for (moment, λ) in poly
                expo = product(moment.conj_part, moment.expl_part)
                @assert expo.degree.explvar == moment.expl_part.degree.explvar
                @assert expo.degree.conjvar == moment.conj_part.degree.conjvar
                # Check the current monomial has correct degree
                if (relaxctx.hierarchykind==:Complex) && ((expo.degree.explvar > relaxctx.di[cstrname]) || (expo.degree.conjvar > relaxctx.di[cstrname]))
                    warn("build_SDPInstance(): Found exponent pair of degree $(expo.degree) > $(relaxctx.di[cstrname]) for Complex hierarchy.\n($(expo), at $((γ, δ)) of MM matrix)")
                elseif (relaxctx.hierarchykind==:Real) && ((expo.degree.explvar > 2*relaxctx.di[cstrname]) || (expo.degree.conjvar != 0))
                    warn("build_SDPInstance(): Found exponent pair of degree $(expo.degree) > 2*$(relaxctx.di[cstrname]) for Real hierarchy.\n($(expo), at $((γ, δ)) of MM matrix)")
                end
                !isnan(λ) || warn("build_SDPInstance(): isNaN ! constraint $cstrname - clique $blocname - mm entry $((γ, δ)) - moment $(expo)")

                # Add the current coeff to the SDP problem
                # Constraints are fα - ∑ Bi.Zi = 0
                if mmt.matrixkind == :SDP || mmt.matrixkind == :SDPC
                    key = (moment, block_name, γ, δ)
                    @assert !haskey(sdpblocks, key)

                    sdpblocks[key] = -λ
                elseif mmt.matrixkind == :Sym || mmt.matrixkind == :SymC
                    key = (moment, block_name, product(γ, δ))
                    haskey(sdplinsym, key) || (sdplinsym[key] = 0)

                    sdplinsym[key] += -λ * (γ!=δ ? 2 : 1)
                else
                    error("build_SDPInstance(): Unhandled matrix kind $(mmt.matrixkind) for ($cstrname, $cliquename)")
                end

            end
        end
    end

    ## Build linear dict
    # Enforce clique coupling constraints on moments
    for (expo, cliques) in mmtrelax_pb.moments_overlap
        expo == Exponent() && continue
        # print_with_color(:light_cyan, "-> $expo - $(collect(cliques))\n")
        @assert length(cliques)>1
        cliqueref = first(cliques)

        refmoment = Moment(expo, cliqueref)
        for clique in setdiff(cliques, [cliqueref])
            curmoment = Moment(expo, clique)
            var = Exponent(get_ccmultvar(relaxctx, expo, cliqueref, clique))

            @assert !haskey(sdplin, (refmoment, var))
            @assert !haskey(sdplin, (curmoment, var))
            sdplin[(refmoment, var)] =  1
            sdplin[(curmoment, var)] = -1
        end
    end

    ## Build constants dict
    for (moment, fαβ) in mmtrelax_pb.objective
        # Determine which moment to affect the current coefficient.

        if !haskey(sdpcst, moment)
            sdpcst[moment] = 0.0
        end

        # Constraints are fα - ∑ Bi.Zi = 0
        sdpcst[moment] += fαβ
    end

    return SDPInstance(block_to_vartype, sdpblocks, sdplinsym, sdplin, sdpcst)
end


"""
    α, β = split_expo(expo::Exponent)

    Split the exponent into two exponents of conjugated and explicit variables in the complex case.
    Real case is not supported yet.
"""
function split_expo(relaxctx::RelaxationContext, expo::Exponent)
    α, β = Exponent(), Exponent()

    for (var, deg) in expo
        add_expod!(α, Exponent(SortedDict(var=>Degree(0, deg.conjvar))))
        add_expod!(β, Exponent(SortedDict(var=>Degree(deg.explvar, 0))))
    end

    if (relaxctx.hierarchykind == :Real) && (α.degree != Degree(0,0))
        error("split_expo(): Inconsistent degree $α, $β found for $(relaxctx.hierarchykind) hierarchy.")
    end
    return α, β
end


function print(io::IO, sdpinst::SDPInstance)
    println(io, " -- SDP Blocks:")
    print(io, sdpinst.blocks)
    println(io, " -- linear part:")
    print(io, sdpinst.lin, sdpinst.linsym)
    println(io, " -- const part:")
    print(io, sdpinst.cst)
    println(io, " -- mat var types:")
    for (blockname, blocktype) in sdpinst.block_to_vartype
        println(io, "   $blockname  \t $blocktype")
    end
end

function print(io::IO, sdpblocks::SDPBlocks; indentedprint=true)
    print_blocksfile(io, sdpblocks; indentedprint=indentedprint, print_header=false)
end

function print(io::IO, sdplin::SDPLin, sdplinsym::SDPLinSym; indentedprint=true)
    print_linfile(io, sdplin, sdplinsym; indentedprint=indentedprint, print_header=false)
end


function print(io::IO, sdpcst::SDPCst; indentedprint=true)
    print_cstfile(io, sdpcst; indentedprint=indentedprint, print_header=false)
end